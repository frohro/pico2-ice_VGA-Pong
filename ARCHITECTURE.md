# VGA System Architecture

## Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        pico2-ice Board                       │
│                                                              │
│  ┌──────────────┐          ┌──────────────────────────────┐ │
│  │   RP2350B    │          │       ICE40UP5K FPGA         │ │
│  │              │          │                              │ │
│  │ ice.fpga()   │ 25 MHz   │  ┌────────────────────────┐  │ │
│  │ Clock API    ├─────────>│  │   vga_timing.sv        │  │ │
│  │              │          │  │  (Sync Generator)      │  │ │
│  └──────────────┘          │  │                        │  │ │
│                            │  │  - H/V Counters        │  │ │
│                            │  │  - Sync Signals        │  │ │
│                            │  │  - Display Enable      │  │ │
│                            │  └───────┬────────────────┘  │ │
│                            │          │                   │ │
│                            │          v                   │ │
│                            │  ┌────────────────────────┐  │ │
│                            │  │      top.sv            │  │ │
│                            │  │  (Color Generator)     │  │ │
│                            │  │                        │  │ │
│                            │  │  - RGB Logic           │  │ │
│                            │  │  - Full Red Screen     │  │ │
│                            │  └───────┬────────────────┘  │ │
│                            │          │                   │ │
│                            │          v                   │ │
│                            │    [FPGA GPIO Pins]          │ │
│                            └──────────┬───────────────────┘ │
└───────────────────────────────────────┼─────────────────────┘
                                        │
                                        │ 14 pins (4R+4G+4B+2Sync)
                                        │
                                        v
                            ┌───────────────────────┐
                            │   Digilent VGA PMOD   │
                            │   (R-2R DAC)          │
                            │                       │
                            │  R[3:0] ──> R-2R ──>  │
                            │  G[3:0] ──> R-2R ──>  │
                            │  B[3:0] ──> R-2R ──>  │
                            │  HSYNC ───────────>   │
                            │  VSYNC ───────────>   │
                            └───────────┬───────────┘
                                        │
                                        │ VGA Cable
                                        │
                                        v
                            ┌───────────────────────┐
                            │    VGA Monitor        │
                            │   640x480 @ 60Hz      │
                            │                       │
                            │   [RED SCREEN]        │
                            └───────────────────────┘
```

## Signal Flow

### Clock Generation (RP2350B)
1. RP2350B generates 25 MHz clock via MicroPython ice.fpga() API
2. Clock signal sent to FPGA via dedicated pin
3. FPGA uses this as pixel clock for VGA timing (close to ideal 25.175 MHz)

### VGA Timing Generation (vga_timing.sv)
1. **Horizontal Counter** (hcount): 0-799 pixels
   - 0-639: Visible area
   - 640-655: Front porch
   - 656-751: Sync pulse (HSYNC low)
   - 752-799: Back porch

2. **Vertical Counter** (vcount): 0-524 lines
   - 0-479: Visible area
   - 480-489: Front porch
   - 490-491: Sync pulse (VSYNC low)
   - 492-524: Back porch

3. **Display Enable**: High when both counters in visible area
4. **Sync Signals**: Negative polarity pulses

### Color Generation (top.sv)
1. Checks display_en signal
2. If enabled (visible area):
   - vga_r = 4'hF (full red)
   - vga_g = 4'h0 (no green)
   - vga_b = 4'h0 (no blue)
3. If disabled (blanking):
   - All colors = 4'h0 (black)

### Digital to Analog Conversion (R-2R DAC)
1. 4-bit digital values for each color
2. R-2R ladder network converts to analog voltage
3. Output range: 0V to ~0.7V per VGA spec
4. 16 levels per color = 4096 total colors

## Timing Specifications

### Pixel Clock
- Frequency: 25 MHz (RP2350B via MicroPython ice.fpga API)
- Target: 25.175 MHz (standard VGA)
- Tolerance: ~0.7% deviation (acceptable for most monitors)
- Period: 40 ns (vs ideal 39.72 ns)

### Horizontal Timing
- Total pixels per line: 800
- Line time: 31.78 μs
- Line frequency: 31.469 kHz

### Vertical Timing
- Total lines per frame: 525
- Frame time: 16.68 ms
- Frame frequency: 59.94 Hz

### Sync Polarity
- HSYNC: Negative (active low)
- VSYNC: Negative (active low)

## Pin Assignments (To Be Updated)

| Signal      | FPGA Pin | Direction | Description                    |
|-------------|----------|-----------|--------------------------------|
| clk_25mhz   | TBD      | Input     | 25.175 MHz from RP2350B       |
| reset_n     | TBD      | Input     | Active-low reset               |
| vga_r[3]    | TBD      | Output    | Red MSB                        |
| vga_r[2]    | TBD      | Output    | Red bit 2                      |
| vga_r[1]    | TBD      | Output    | Red bit 1                      |
| vga_r[0]    | TBD      | Output    | Red LSB                        |
| vga_g[3]    | TBD      | Output    | Green MSB                      |
| vga_g[2]    | TBD      | Output    | Green bit 2                    |
| vga_g[1]    | TBD      | Output    | Green bit 1                    |
| vga_g[0]    | TBD      | Output    | Green LSB                      |
| vga_b[3]    | TBD      | Output    | Blue MSB                       |
| vga_b[2]    | TBD      | Output    | Blue bit 2                     |
| vga_b[1]    | TBD      | Output    | Blue bit 1                     |
| vga_b[0]    | TBD      | Output    | Blue LSB                       |
| vga_hsync   | TBD      | Output    | Horizontal sync (active low)   |
| vga_vsync   | TBD      | Output    | Vertical sync (active low)     |

**Note**: Update pins.pcf with actual pin numbers from pico2-ice schematic.

## Resource Utilization

The design is very lightweight:
- **Logic Cells**: < 100 (mostly counters and comparators)
- **Block RAM**: 0 (no frame buffer)
- **PLLs**: 0 (clock provided externally)
- **I/O Pins**: 16 total

This leaves plenty of resources for adding features like:
- Pattern generators
- Frame buffers
- Graphics acceleration
- Video processing

## Future Enhancements

1. **Pattern Generation**
   - Test patterns (color bars, checkerboard)
   - Gradients and color wheels
   
2. **Graphics Engine**
   - Line drawing (Bresenham algorithm)
   - Rectangle and circle primitives
   - Sprite rendering
   
3. **Text Display**
   - Character ROM (8x8 or 8x16 fonts)
   - Text buffer in block RAM
   - Hardware cursor
   
4. **Frame Buffer**
   - Off-chip SRAM interface
   - Double buffering for smooth animation
   - Hardware scrolling
   
5. **Video Effects**
   - Color space conversion
   - Scaling and filtering
   - Overlay graphics
