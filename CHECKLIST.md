# Pre-Build Checklist

Before you build and flash the VGA system, make sure you complete these steps:

## ✓ File Verification

- [x] vga_timing.sv created - VGA timing generator
- [x] top.sv created - Top-level module
- [x] vga_tb.sv created - Testbench for simulation
- [x] Makefile updated - Build configuration
- [x] flash_bin.py updated - Flash script with clock configuration
- [x] pins.pcf created - Pin constraints (NEEDS UPDATING!)
- [x] Documentation created - README, QUICKSTART, ARCHITECTURE

## ⚠ ACTION REQUIRED

### 1. Update Pin Constraints (pins.pcf)

**STATUS: INCOMPLETE - YOU MUST DO THIS!**

The `pins.pcf` file currently has placeholder pin numbers. You need to update it with actual pins from your hardware setup.

Reference files:
- pico2-ice schematic (for FPGA side pins)
- pmodvga_sch.pdf (for VGA PMOD pins)

Required pin assignments:
- [ ] clk_25mhz - Clock input from RP2350B
- [ ] reset_n - Reset button (active low)
- [ ] vga_r[3:0] - Red channel (4 bits)
- [ ] vga_g[3:0] - Green channel (4 bits)
- [ ] vga_b[3:0] - Blue channel (4 bits)
- [ ] vga_hsync - Horizontal sync
- [ ] vga_vsync - Vertical sync

**IMPORTANT**: ICE40UP5K in SG48 package has specific pin numbers (1-48). Make sure your pin numbers are valid!

### 2. Hardware Connections

- [ ] pico2-ice USB connected to computer
- [ ] VGA PMOD connected to correct FPGA pins
- [ ] VGA cable connected from PMOD to monitor
- [ ] Monitor powered on and set to correct input
- [ ] Monitor supports 640x480@60Hz (most do)

## ✓ Software Prerequisites

Check that you have all required tools installed:

```bash
# Check for OSS CAD Suite tools
which yosys
which nextpnr-ice40
which icepack

# Check for mpremote
which mpremote
pip show mpremote

# Check for iverilog (optional, for simulation)
which iverilog
```

Required installations:
- [ ] OSS CAD Suite (yosys, nextpnr-ice40, icepack)
- [ ] mpremote (pip install mpremote)
- [ ] iverilog (optional, for simulation)

## ✓ Build Process

Once the above is complete, follow this sequence:

### Step 1: Clean Previous Builds
```bash
make clean
```

### Step 2: (Optional) Run Simulation
```bash
make sim
```
Expected output: Testbench passes all checks

### Step 3: Build Bitstream
```bash
make
```
Expected output: 
- Yosys synthesis completes
- nextpnr place & route completes
- icepack generates vga.bin
- No errors reported

### Step 4: Flash FPGA
```bash
make flash
```
Expected output:
- Files copied to pico2-ice
- Flash script executes
- "FPGA started successfully!" message
- "VGA display should now be showing a red screen"

### Step 5: Test Display
- [ ] Monitor shows "signal detected"
- [ ] Screen displays solid red color
- [ ] Image is stable (no flickering or rolling)
- [ ] No artifacts or noise

## 🐛 If Something Goes Wrong

### Build Fails
1. Check syntax errors in .sv files
2. Verify pins.pcf has valid pin numbers
3. Check OSS CAD Suite version
4. Look for error messages in terminal output

### Flash Fails  
1. Check USB connection
2. Verify pico2-ice is in MicroPython mode
3. Try `mpremote connect list` to see devices
4. Check that vga.bin was generated

### No Display
1. Verify clock is configured (check flash_bin.py frequency parameter)
2. Check FPGA CDONE LED is lit
3. Test with different monitor
4. Verify all cable connections
5. Check pin assignments

### Wrong Colors or Noise
1. Verify R-2R DAC connections
2. Check pin ordering (MSB to LSB)
3. Verify sync signal connections
4. Check for ground loops

## 📚 Help Resources

- **QUICKSTART.md** - Quick reference and troubleshooting
- **README.md** - Detailed documentation
- **ARCHITECTURE.md** - System design details
- **PROJECT_SUMMARY.md** - Complete overview

## ✅ Success Criteria

You're done when:
- ✓ Build completes with no errors
- ✓ Flash succeeds
- ✓ Monitor displays solid red screen
- ✓ Image is stable and clear

Then you can start experimenting with colors and patterns! 🎨

---

**REMEMBER**: The most critical step is updating pins.pcf with your actual hardware pinout!
