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

## Pin Assignments

| Signal      | FPGA Pin | ICE Pin     | RP2350B Pin | LA Channel | Direction | Description                    |
|-------------|----------|-------------|-------------|------------|-----------|--------------------------------|
| clk_25mhz   | 35       | ICE_35      | GPIO21      | 02         | Input     | 25 MHz clock from RP2350B     |
| reset_n     | 10       | ICE_10      | -           | -          | Input     | Active-low reset               |
| vga_r[3]    | 47       | ICE_47      | -           | -          | Output    | Red MSB                        |
| vga_r[2]    | 45       | ICE_45      | -           | -          | Output    | Red bit 2                      |
| vga_r[1]    | 2        | ICE_2       | -           | -          | Output    | Red bit 1                      |
| vga_r[0]    | 4        | ICE_4       | -           | -          | Output    | Red LSB                        |
| vga_g[3]    | 31       | ICE_31      | -           | -          | Output    | Green MSB                      |
| vga_g[2]    | 34       | ICE_34      | GPIO35      | 16         | Output    | Green bit 2                    |
| vga_g[1]    | 38       | ICE_38      | GPIO39      | 20         | Output    | Green bit 1                    |
| vga_g[0]    | 43       | ICE_43      | GPIO43      | 24         | Output    | Green LSB                      |
| vga_b[3]    | 48       | ICE_48      | -           | -          | Output    | Blue MSB                       |
| vga_b[2]    | 46       | ICE_46      | -           | -          | Output    | Blue bit 2                     |
| vga_b[1]    | 44       | ICE_44      | -           | -          | Output    | Blue bit 1                     |
| vga_b[0]    | 3        | ICE_3       | -           | -          | Output    | Blue LSB                       |
| vga_hsync   | 27       | ICE_27      | GPIO20      | 01         | Output    | Horizontal sync (active low)   |
| vga_vsync   | 18       | ICE_18      | GPIO27      | 08         | Output    | Vertical sync (active low)     |

### Debug Probe Points (Obsolete)

**Note**: The probe points are no longer needed since hsync and vsync are now connected to GPIO-accessible pins that can be directly monitored on the LogicAnalyzer (Channels 01 and 08).

**Note**: Probe points carry identical signals to main sync outputs, allowing waveform capture while monitor remains connected. LogicAnalyzer channels are based on the pico2-ice GPIO mapping (Channel = GPIO - 19).

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
