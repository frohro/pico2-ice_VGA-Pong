# Quick Start Guide

## Setup Steps

### 1. Update Pin Assignments

Edit `pins.pcf` with the actual pin numbers for your hardware setup:
- Check the pico2-ice schematic for FPGA pin connections
- Check the Digilent VGA PMOD pinout (see `pmodvga_sch.pdf`)
- Update all pin assignments in `pins.pcf`

### 2. Build the FPGA Bitstream

```bash
make clean
make
```

This will:
- Synthesize the SystemVerilog code with Yosys
- Place and route with nextpnr-ice40
- Generate the bitstream file `vga.bin`

### 3. Flash to FPGA

```bash
make flash
```

This will:
- Copy `vga.bin` to the pico2-ice
- Copy `flash_bin.py` to the pico2-ice  
- Run the flash script to program the FPGA
- Configure RP2350B to provide 25 MHz clock to FPGA

### 4. Test the Display

Connect a VGA monitor and you should see a solid red screen!

## Troubleshooting

### Build Errors

**Error: "command not found: yosys"**
- Install OSS CAD Suite from https://github.com/YosysHQ/oss-cad-suite-build

**Syntax errors in SystemVerilog**
- Ensure you're using Yosys with SystemVerilog support (-sv flag)
- Check that all module instantiations match their definitions

**Pin constraint errors**
- Verify all pin numbers exist on ICE40UP5K SG48 package
- Check for duplicate pin assignments

### Flash Errors

**Error: "Could not open vga.bin"**
- Make sure the build completed successfully
- Check that `vga.bin` exists in the current directory

**Error: "mpremote: command not found"**
- Install with: `pip install mpremote`

**Error: "Device not found"**
- Check USB connection to pico2-ice
- Verify pico2-ice is in MicroPython mode (not bootloader)

### Display Problems

**No display / Monitor says "No Signal"**
1. Check VGA cable connections
2. Verify monitor supports 640x480@60Hz
3. Check that FPGA is programmed (CDONE LED should be lit)
4. Verify clock frequency in flash_bin.py is set correctly (frequency=25)

**Display shows wrong color or noise**
1. Check pin assignments in `pins.pcf`
2. Verify R-2R DAC connections  
3. Check sync signal polarity settings
4. Ensure clock frequency is correct (25.175 MHz ±0.5%)

**Display is unstable or rolling**
1. Clock frequency mismatch - check flash_bin.py frequency parameter
2. Verify timing constraints are met (check build logs)
3. Ensure proper ground connections between boards
4. Try a different VGA cable

## Making Changes

### Change the Display Color

Edit `top.sv`, find the color generation section:

```systemverilog
if (display_en) begin
    vga_r <= 4'hF;  // Change these values
    vga_g <= 4'h0;  // 0x0 = off, 0xF = full brightness
    vga_b <= 4'h0;
end
```

Then rebuild and reflash:
```bash
make && make flash
```

### Create Patterns

Modify the color generation logic to use `hcount` and `vcount`:

```systemverilog
// Vertical stripes
vga_r <= hcount[7:4];
vga_g <= 4'h0;
vga_b <= 4'h0;

// Checkerboard
vga_r <= {4{hcount[4] ^ vcount[4]}};
vga_g <= 4'h0;
vga_b <= 4'h0;
```

## Common Make Targets

- `make` or `make all` - Build the bitstream
- `make sim` - Run the testbench simulation
- `make flash` - Flash the bitstream to FPGA
- `make clean` - Remove generated files
- `make help` - Show all available targets

## Files You May Need to Edit

1. **pins.pcf** - Pin assignments (REQUIRED before first build)
2. **top.sv** - Color generation logic (to change display)
3. **flash_bin.py** - Clock frequency parameter (if needed)

## Files You Probably Won't Need to Edit

- **vga_timing.sv** - Standard VGA timing (don't change unless you know what you're doing)
- **Makefile** - Build configuration (already set up)
- **flash_bin.py** - Flash script (already configured)

## Next Steps

Once you have the red screen working:

1. **Experiment with colors** - Try different RGB combinations
2. **Add patterns** - Use hcount/vcount to create designs
3. **Add inputs** - Connect buttons to change colors
4. **Create animations** - Use frame_start signal to update state
5. **Add graphics** - Implement line/rectangle drawing
6. **Display text** - Add a character ROM

Refer to `README.md` and `ARCHITECTURE.md` for more detailed information.
