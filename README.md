--# VGA Display System for pico2-ice

This project implements a VGA 640x480@60Hz display controller for the pico2-ice FPGA board (ICE40UP5K). The system displays a full-screen red color as a starting point for further VGA applications.

## Features

- **VGA Timing Generator**: Generates proper sync signals for 640x480@60Hz resolution
- **4-bit Color Channels**: Supports 4 bits per RGB channel (4096 colors total)
- **R-2R DAC Compatible**: Designed to work with Digilent R-2R DAC for analog output
- **Modern SystemVerilog**: Uses best practices and latest coding standards

## Hardware Requirements

- **pico2-ice board** with ICE40UP5K FPGA
- **RP2350B** provides clock to FPGA (configured via MicroPython)
- **Digilent VGA PMOD** with R-2R DAC or equivalent
- **VGA Monitor** supporting 640x480@60Hz

## VGA Timing Specifications

Based on specifications from [http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html](http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html)

### Horizontal Timing (640x480@60Hz)
- Pixel clock: 25.175 MHz
- Visible area: 640 pixels
- Front porch: 16 pixels
- Sync pulse: 96 pixels (negative polarity)
- Back porch: 48 pixels
- Total: 800 pixels per line
- Line frequency: 31.469 kHz

### Vertical Timing
- Visible area: 480 lines
- Front porch: 10 lines
- Sync pulse: 2 lines (negative polarity)
- Back porch: 33 lines
- Total: 525 lines per frame
- Frame frequency: 59.94 Hz

## File Structure

```
.
├── README.md           # This file
├── Makefile           # Build automation
├── flash_bin.py       # FPGA flash script for pico2-ice
├── pins.pcf           # Pin constraints (needs pinout update)
├── top.sv             # Top-level module
├── vga_timing.sv      # VGA timing generator
└── vga_tb.sv          # Testbench for verification
```

## Pin Configuration

**IMPORTANT**: The `pins.pcf` file contains placeholder pin numbers. You must update it with the actual pico2-ice pinout for your VGA connection.

Required signals:
- `clk_25mhz`: 25.175 MHz clock input from RP2350B
- `reset_n`: Active-low reset button
- `vga_r[3:0]`: 4-bit red channel (to R-2R DAC)
- `vga_g[3:0]`: 4-bit green channel (to R-2R DAC)
- `vga_b[3:0]`: 4-bit blue channel (to R-2R DAC)
- `vga_hsync`: Horizontal sync signal
- `vga_vsync`: Vertical sync signal

## Building the Project

### Prerequisites

Install the OSS CAD Suite:
```bash
# OSS CAD Suite includes yosys, nextpnr-ice40, icepack, etc.
# Download from: https://github.com/YosysHQ/oss-cad-suite-build
```

Install mpremote for pico2-ice programming:
```bash
pip install mpremote
```

### Build Steps

1. **Synthesize and generate bitstream:**
   ```bash
   make
   ```

2. **Run simulation (optional):**
   ```bash
   make sim
   ```

3. **Flash to FPGA:**
   ```bash
   make flash
   ```

## Usage

1. Update `pins.pcf` with correct pin assignments for your hardware
2. Connect VGA PMOD/R-2R DAC to FPGA pins
3. Connect VGA monitor
4. Build and flash the design: `make && make flash`
5. The RP2350B will provide a 25 MHz clock to the FPGA (via `flash_bin.py`)
6. The screen should display solid red color

## Modifying Colors

To change the displayed color, edit the `top.sv` file in the color generation section:

```systemverilog
if (display_en) begin
    vga_r <= 4'hF;  // Red intensity (0x0 to 0xF)
    vga_g <= 4'h0;  // Green intensity (0x0 to 0xF)
    vga_b <= 4'h0;  // Blue intensity (0x0 to 0xF)
end
```

Examples:
- White: `vga_r <= 4'hF; vga_g <= 4'hF; vga_b <= 4'hF;`
- Blue: `vga_r <= 4'h0; vga_g <= 4'h0; vga_b <= 4'hF;`
- Yellow: `vga_r <= 4'hF; vga_g <= 4'hF; vga_b <= 4'h0;`
- Gray: `vga_r <= 4'h8; vga_g <= 4'h8; vga_b <= 4'h8;`

## Next Steps

This basic red screen is a foundation for more complex VGA applications:

1. **Pattern Generation**: Display test patterns, checkerboards, gradients
2. **Graphics Primitives**: Draw lines, rectangles, circles
3. **Text Display**: Add character ROM for text rendering
4. **Frame Buffer**: Implement memory-based frame buffer
5. **Animation**: Create moving objects or sprites
6. **Video Input**: Process and display video signals

## Troubleshooting

### No Display
- Check VGA cable connections
- Verify monitor supports 640x480@60Hz
- Confirm 25.175 MHz clock is present at FPGA
- Check sync signal polarities (should be negative)

### Wrong Colors
- Verify R-2R DAC connections
- Check pin assignments in `pins.pcf`
- Ensure correct bit ordering (MSB to LSB)

### Unstable Image
- Verify clock stability
- Check for timing violations in synthesis report
- Ensure proper ground connections

## References

- [VGA Signal Timing Specifications](http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html)
- [pico2-ice Documentation](https://github.com/tinyvision-ai-inc/pico-ice)
- [ICE40 FPGA Documentation](https://www.latticesemi.com/iCE40)

## License

This project is provided as educational material for digital design courses.
