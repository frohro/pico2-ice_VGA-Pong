# Makefile for VGA FPGA Project (pico2-ice)
# 
# This Makefile provides targets for:
# - Synthesis and place & route
# - Simulation with testbench
# - Programming the FPGA
# - Cleanup
#
# Make sure you have the appropriate FPGA tools installed
# (e.g., Yosys, nextpnr, icestorm for iCE40 FPGAs)

# Project name and source files
PROJECT = vga
TOP_MODULE = top
SOURCES = vga_timing.sv sprite_renderer.sv pong_game.sv top.sv
TESTBENCH = vga_tb.sv
CONSTRAINT_FILE = pins.pcf

# FPGA part (ICE40UP5K in 48-pin package)
FPGA_FAMILY = ice40
FPGA_PACKAGE = sg48
FPGA_DEVICE = up5k

# Tools (adjust paths if needed)
YOSYS = yosys
PNR = nextpnr-ice40
PACK = icepack
PROG = iceprog
SIM = iverilog
VIEWER = gtkwave
MPREMOTE = mpremote
FLASH_SCRIPT = flash_bin.py

# Firmware files
MICROPYTHON_UF2 = firmware/pico-ice_micropython_float_frequencies.uf2
LOGICANALYZER_UF2 = firmware/LogicAnalyzer.uf2
REBOOT_BOOTSEL = ./reboot_bootsel.sh
FLASH_FIRMWARE = ./flash.sh

# Default target
all: $(PROJECT).bin

# Synthesis
$(PROJECT).json: $(SOURCES)
	@echo "=== Synthesis ==="
	$(YOSYS) -p "read_verilog -sv $(SOURCES); synth_ice40 -top $(TOP_MODULE) -json $@"

# Place and Route
$(PROJECT).asc: $(PROJECT).json $(CONSTRAINT_FILE)
	@echo "=== Place and Route ==="
	$(PNR) --$(FPGA_DEVICE) --package $(FPGA_PACKAGE) --json $(PROJECT).json --pcf $(CONSTRAINT_FILE) --asc $@

# Generate bitstream
$(PROJECT).bin: $(PROJECT).asc
	@echo "=== Generate Bitstream ==="
	$(PACK) $(PROJECT).asc $@

# Program FPGA using iceprog (traditional method)
program: $(PROJECT).bin
	@echo "=== Programming FPGA with iceprog ==="
	$(PROG) $<

# Check if MicroPython is running on pico2-ice
check-micropython:
	@echo "=== Checking for MicroPython on pico2-ice ==="
	@if $(MPREMOTE) exec "print('OK')" 2>/dev/null | grep -q "OK"; then \
		echo "✓ MicroPython detected"; \
		exit 0; \
	else \
		echo "✗ MicroPython not detected"; \
		exit 1; \
	fi

# Ensure MicroPython firmware is loaded (load if not present)
ensure-micropython: $(MICROPYTHON_UF2)
	@echo "=== Ensuring MicroPython firmware is loaded ==="
	@if $(MPREMOTE) exec "print('OK')" 2>/dev/null | grep -q "OK"; then \
		echo "✓ MicroPython already running"; \
	else \
		echo "⚠ MicroPython not detected, flashing firmware..."; \
		chmod +x $(REBOOT_BOOTSEL) $(FLASH_FIRMWARE); \
		$(FLASH_FIRMWARE) $(MICROPYTHON_UF2); \
		echo "⏳ Waiting for MicroPython to start (10 seconds)..."; \
		sleep 10; \
		echo "⏳ Attempting connection..."; \
		for i in 1 2 3 4 5; do \
			if $(MPREMOTE) exec "print('OK')" 2>/dev/null | grep -q "OK"; then \
				echo "✓ MicroPython firmware loaded successfully"; \
				exit 0; \
			fi; \
			echo "   Retry $$i/5..."; \
			sleep 2; \
		done; \
		echo "✗ MicroPython not responding. Please check connection."; \
		echo "   Thonny may have exclusive access - close it and try again."; \
		exit 1; \
	fi

# Flash FPGA bitstream using pico2-ice with MicroPython (auto-load MicroPython if needed)
flash: $(PROJECT).bin $(FLASH_SCRIPT) ensure-micropython
	@echo "=== Flashing FPGA via pico2-ice with MicroPython ==="
	@echo "Copying bitstream and executing flash script..."
	$(MPREMOTE) fs cp $(PROJECT).bin :$(PROJECT).bin + run $(FLASH_SCRIPT)
	@echo "✓ FPGA flashing complete!"

# Flash FPGA and then switch to LogicAnalyzer firmware for debugging
flash-logic: $(PROJECT).bin $(FLASH_SCRIPT) $(LOGICANALYZER_UF2) ensure-micropython
	@echo "=== Flashing FPGA and switching to LogicAnalyzer ==="
	@echo "Step 1: Flashing FPGA bitstream..."
	$(MPREMOTE) fs cp $(PROJECT).bin :$(PROJECT).bin + run $(FLASH_SCRIPT)
	@echo "✓ FPGA bitstream loaded"
	@echo "Step 2: Switching to LogicAnalyzer firmware..."
	chmod +x $(REBOOT_BOOTSEL) $(FLASH_FIRMWARE)
	$(FLASH_FIRMWARE) $(LOGICANALYZER_UF2)
	@echo "✓ LogicAnalyzer firmware loaded"
	@echo ""
	@echo "Ready for logic analysis! Connect to the pico2-ice with LogicAnalyzer software."
	@echo "To flash again, run 'make flash' (will auto-reload MicroPython)"

# Alternative flash target that does everything in one command (deprecated - use 'flash' instead)
flash-direct: $(PROJECT).bin $(FLASH_SCRIPT)
	@echo "=== Direct Flash via pico2-ice ==="
	$(MPREMOTE) fs cp $(PROJECT).bin : + run $(FLASH_SCRIPT)

# Simulation
sim: $(TESTBENCH) $(SOURCES)
	@echo "=== Running Simulation ==="
	$(SIM) -g2012 -o $(PROJECT)_sim $(TESTBENCH) $(SOURCES)
	./$(PROJECT)_sim

# Simulate sprite renderer
sim-sprite: sprite_renderer_tb.sv sprite_renderer.sv
	@echo "=== Running Sprite Renderer Simulation ==="
	$(SIM) -g2012 -o sprite_sim sprite_renderer_tb.sv sprite_renderer.sv
	./sprite_sim

# Simulate pong game logic
sim-pong: pong_game_tb.sv pong_game.sv
	@echo "=== Running Pong Game Simulation ==="
	$(SIM) -g2012 -o pong_sim pong_game_tb.sv pong_game.sv
	./pong_sim

# Run all simulations
sim-all: sim sim-sprite sim-pong
	@echo "=== All Simulations Complete ==="

# View simulation waveforms (requires testbench to generate VCD)
wave: sim
	@echo "=== Opening Waveform Viewer ==="
	$(VIEWER) vga_tb.vcd &

# Synthesis report
report: $(PROJECT).json
	@echo "=== Synthesis Report ==="
	$(YOSYS) -p "read_json $(PROJECT).json; stat"

# Clean generated files
clean:
	@echo "=== Cleaning ==="
	rm -f $(PROJECT).json $(PROJECT).asc $(PROJECT).bin
	rm -f $(PROJECT)_sim $(PROJECT)_tb.vcd
	rm -f sprite_sim sprite_renderer_tb.vcd
	rm -f pong_sim pong_game_tb.vcd
	rm -f yosys.log nextpnr.log
	$(MAKE) clean-verilator

# Clean files on pico2-ice as well
clean-all: clean
	@echo "=== Cleaning pico2-ice files ==="
	-$(MPREMOTE) fs rm $(PROJECT).bin
	-$(MPREMOTE) fs rm $(FLASH_SCRIPT)

# Note: pins.pcf file should be created manually with proper pin assignments

# Help target
help:
	@echo "Available targets:"
	@echo "  all            - Synthesize and generate bitstream"
	@echo "  sim            - Run VGA timing simulation with testbench"
	@echo "  sim-sprite     - Run sprite renderer simulation"
	@echo "  sim-pong       - Run pong game logic simulation (cycle accurate)"
	@echo "  sim-all        - Run all simulations"
	@echo "  sim-visual     - Build visual Pong simulator with Verilator (8x faster)"
	@echo "  run-visual     - Build and run visual Pong simulator"
	@echo "  wave           - View simulation waveforms"
	@echo ""
	@echo "FPGA Programming:"
	@echo "  flash          - Flash FPGA (auto-loads MicroPython if needed, leaves it running)"
	@echo "  flash-logic    - Flash FPGA + switch to LogicAnalyzer for waveform viewing"
	@echo "  program        - Program FPGA with iceprog (traditional, requires USB Blaster)"
	@echo ""
	@echo "Firmware Management:"
	@echo "  check-micropython   - Check if MicroPython is currently running"
	@echo "  ensure-micropython  - Load MicroPython firmware (only if not present)"
	@echo ""
	@echo "Maintenance:"
	@echo "  report       - Show synthesis report"
	@echo "  clean        - Remove generated files"
	@echo "  clean-all    - Remove local and pico2-ice files"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Firmware Files Required:"
	@echo "  - $(MICROPYTHON_UF2) - For FPGA programming"
	@echo "  - $(LOGICANALYZER_UF2) - For logic analysis"
	@echo ""
	@echo "Visual Simulator Requirements:"
	@echo "  - Verilator (HDL to C++ compiler)"
	@echo "  - OpenGL and GLUT libraries"
	@echo "  Install on Ubuntu: sudo apt-get install verilator libglu1-mesa-dev freeglut3-dev"
	@echo ""
	@echo "Note: pins.pcf must exist with proper pin assignments"
	@echo "Note: No need to manually press BOOTSEL or unplug/replug USB!"

# VGA Simulator with Verilator (visual simulation)
VERILATOR = verilator
PONG_SOURCES_SIM = display_pong.v pong_game.sv sprite_renderer.sv
VERILATOR_FLAGS = -Wall --cc --exe --build
VERILATOR_LDFLAGS = -LDFLAGS -lglut -LDFLAGS -lGLU -LDFLAGS -lGL

# Build the Pong visual simulator with Verilator
sim-visual: $(PONG_SOURCES_SIM) pong_simulator.cpp
	@echo "=== Building Pong Visual Simulator with Verilator ==="
	@echo "This requires verilator, OpenGL, and GLUT to be installed"
	@echo "On Ubuntu: sudo apt-get install verilator libglu1-mesa-dev freeglut3-dev mesa-common-dev"
	$(VERILATOR) $(VERILATOR_FLAGS) pong_simulator.cpp display_pong.v pong_game.sv sprite_renderer.sv $(VERILATOR_LDFLAGS)
	@echo ""
	@echo "Build complete! Run './obj_dir/Vdisplay_pong' to start the visual simulation"

# Run the visual simulator
run-visual: sim-visual
	@echo "=== Running Pong Visual Simulator ==="
	./obj_dir/Vdisplay_pong

# Clean Verilator build files
clean-verilator:
	@echo "=== Cleaning Verilator files ==="
	rm -rf obj_dir

# Phony targets
.PHONY: all sim sim-sprite sim-pong sim-all wave program flash flash-logic flash-direct check-micropython ensure-micropython report clean clean-all help sim-visual run-visual clean-verilator

# Note: You may need to adjust tool names and options based on your specific
# FPGA toolchain and target device. Common alternatives:
# - For Lattice ECP5: nextpnr-ecp5, ecppack, openocd
# - For Xilinx: vivado, xst
# - For Altera: quartus