--# Pico2-Ice VGA Pong 🎮

FPGA-based Pong game for the pico2-ice board (ICE40UP5K) with 640x480@60Hz VGA output. Features sprite-based rendering, realistic physics, paddle AI, and automatic firmware management.

![VGA Output](https://img.shields.io/badge/VGA-640x480@60Hz-blue)
![FPGA](https://img.shields.io/badge/FPGA-iCE40UP5K-green)
![License](https://img.shields.io/badge/license-Educational-orange)

## ✨ Features

- 🎮 **Classic Pong Gameplay** - Ball physics with elastic collisions and paddle AI
- 🎨 **Sprite-Based Rendering** - 16×16 white ball, 8×64 yellow paddle on red background
- ⚡ **Configurable Speed** - Easy parameters: 400 px/s horizontal, 200 px/s vertical
- 🔄 **Automatic Firmware Management** - Seamless switching between MicroPython and LogicAnalyzer
- 🖥️ **Visual Simulator** - Real-time OpenGL simulator using Verilator (8x speed boost)
- 📊 **Comprehensive Testing** - Full testbench suite with Icarus Verilog
- 🔍 **Debug-Friendly** - Probe points for oscilloscope access without cable juggling
- 🚀 **No BOOTSEL Button** - Automatic firmware loading, no manual rebooting

## 🎯 Quick Start

```bash
# Flash FPGA and keep MicroPython for quick iteration
make flash

# Flash FPGA and switch to LogicAnalyzer for waveform capture
make flash-logic

# Run visual simulator (8x faster than real-time)
make run-visual

# Run cycle-accurate testbench
make sim-pong
```

## 📋 Requirements

### Hardware
- **pico2-ice board** with ICE40UP5K FPGA
- **VGA monitor** supporting 640x480@60Hz
- **VGA connection** (R-2R DAC or direct connection)
- **USB cable** for programming

### Software
- **OSS CAD Suite** - Yosys, nextpnr-ice40, icepack
- **Python 3** with `mpremote` for device programming
- **Verilator** (optional) - For visual simulator
- **OpenGL/GLUT** (optional) - For visual simulator

Install dependencies on Ubuntu:
```bash
pip install mpremote
sudo apt-get install verilator libglu1-mesa-dev freeglut3-dev
```

## 📂 Project Structure

```
├── top.sv                 # Top-level module with probe outputs
├── vga_timing.sv         # VGA timing generator (640x480@60Hz)
├── pong_game.sv          # Game physics and paddle AI
├── sprite_renderer.sv    # Sprite rendering engine
├── display_pong.v        # Simulation wrapper
├── pong_simulator.cpp    # Verilator + OpenGL visual simulator
├── flash_bin.py          # FPGA flash script for MicroPython
├── reboot_bootsel.sh     # Automatic BOOTSEL entry (no button!)
├── flash.sh              # Firmware management script
├── Makefile              # Build automation
├── pins.pcf              # Pin constraints for pico2-ice
└── firmware/             # Pre-built firmware files
    ├── pico-ice_micropython_float_frequencies.uf2
    └── LogicAnalyzer.uf2
```

### Firmware Files

The `firmware/` directory contains pre-built firmware files:

- **`pico-ice_micropython_float_frequencies.uf2`** - MicroPython firmware for FPGA programming
  - Source: [tinyvision-ai-inc/pico-ice-micropython](https://github.com/tinyvision-ai-inc/pico-ice-micropython)
  - Used for flashing FPGA bitstreams via `mpremote`

- **`LogicAnalyzer.uf2`** - Logic analyzer firmware for waveform capture
  - Source: [gusmanb/logicanalyzer](https://github.com/gusmanb/logicanalyzer)
  - Used with LogicAnalyzer desktop software for debugging

**To update firmware files:** Download latest releases from the source repositories and replace the files in `firmware/`.

## 🎮 Game Specifications

- **Ball**: 16×16 pixels, white color
- **Paddle**: 8×64 pixels, yellow color, left edge
- **Background**: Solid red (4-bit RGB = F00)
- **Ball Speed**: 400 pixels/sec horizontal, 200 pixels/sec vertical
- **Paddle Speed**: 200 pixels/sec (matches ball vertical speed)
- **AI Behavior**: Paddle tracks ball center, smooth speed-limited movement
- **Physics**: Elastic collisions with walls and paddle

### Adjusting Speed

Edit `pong_game.sv`:
```systemverilog
localparam BALL_SPEED_H = 400;      // Horizontal (pixels/sec)
localparam BALL_SPEED_V = 200;      // Vertical (pixels/sec)  
localparam PADDLE_SPEED_VAL = 200;  // Paddle tracking (pixels/sec)
```

## 🛠️ Building and Flashing

### Standard Workflow

```bash
# Build bitstream
make

# Flash to FPGA (auto-loads MicroPython if needed)
make flash
```

### Development with LogicAnalyzer

```bash
# Flash FPGA and switch to LogicAnalyzer firmware
make flash-logic

# Capture waveforms with LogicAnalyzer software
# When done, reflash normally - MicroPython auto-loads
make flash
```

### Pin Assignments

The design includes duplicate sync signal outputs for easy oscilloscope probing:

| Signal | Monitor Pin | Probe Pin | Description |
|--------|------------|-----------|-------------|
| `vga_hsync` | 20 | 42 | Horizontal sync (~31.5 kHz) |
| `vga_vsync` | 27 | 36 | Vertical sync (~60 Hz) |
| `vga_hsync_probe` | - | 42 | Probe point |
| `vga_vsync_probe` | - | 36 | Probe point |

## 🖥️ Visual Simulation

Run the Verilator-based visual simulator to see the game without hardware:

```bash
# Build and run
make run-visual

# Just build
make sim-visual
./obj_dir/Vdisplay_pong
```

**Note**: Simulator runs 8x faster than real-time by skipping cycles (configurable in `pong_simulator.cpp`).

## 🧪 Testing

### Cycle-Accurate Testbenches

```bash
make sim-pong    # Test game logic
make sim-sprite  # Test sprite renderer  
make sim         # Test VGA timing
make sim-all     # Run all tests
```

### View Waveforms

```bash
make sim-pong
gtkwave pong_game_tb.vcd
```

## 🔧 Firmware Management

The build system automatically handles firmware switching:

```bash
make check-micropython    # Check current firmware
make ensure-micropython   # Load MicroPython if needed
make flash               # Auto-switches to MicroPython, flashes FPGA
make flash-logic         # Flashes FPGA, switches to LogicAnalyzer
```

**No manual intervention required** - scripts handle BOOTSEL mode entry automatically!

## 📐 VGA Timing

### Specifications (640x480@60Hz)

**Horizontal (31.469 kHz)**
- Visible: 640 pixels
- Front porch: 16 pixels
- Sync: 96 pixels (negative polarity)
- Back porch: 48 pixels
- Total: 800 pixels

**Vertical (59.94 Hz)**
- Visible: 480 lines
- Front porch: 10 lines
- Sync: 2 lines (negative polarity)
- Back porch: 33 lines
- Total: 525 lines

**Clock**: 25.175 MHz (provided by RP2350B via MicroPython)

## 🐛 Troubleshooting

### No Display
- Check VGA cable and monitor input selection
- Verify monitor supports 640x480@60Hz
- Run `make flash` to ensure proper programming

### LogicAnalyzer Not Responding
- Close Thonny or other tools using the serial port
- Run `make flash-logic` again
- Check USB connection

### Build Errors
- Ensure OSS CAD Suite is in PATH
- Verify all source files are present
- Check synthesis output: `make report`

### Simulation Slow
- Use `make run-visual` instead of `make sim-pong`
- Visual simulator runs 8x faster
- Adjust `CYCLE_SKIP` in `pong_simulator.cpp` for more speed

## 🚀 Future Enhancements

- [ ] Add player-controlled paddle (button input)
- [ ] Score display with 7-segment style numbers
- [ ] Sound effects via PWM audio
- [ ] Multiple difficulty levels
- [ ] Two-player mode
- [ ] Menu system
- [ ] High score tracking

## 📚 References

- [VGA Timing Specifications](http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html)
- [pico2-ice Documentation](https://github.com/tinyvision-ai-inc/pico-ice)
- [ICE40UP5K Datasheet](https://www.latticesemi.com/iCE40)

## 📄 License

Educational project for digital design coursework.

## 🙏 Acknowledgments

- Original VGA simulation framework by [Saman Mohseni](https://github.com/SamanMohseni)
- Built with OSS CAD Suite and Yosys toolchain
- MicroPython firmware from [pico-ice-micropython](https://github.com/tinyvision-ai-inc/pico-ice-micropython)
- LogicAnalyzer firmware from [logicanalyzer](https://github.com/gusmanb/logicanalyzer)
