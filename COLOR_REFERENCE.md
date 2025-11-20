# VGA Color Reference

Quick reference for 4-bit RGB color values to use in `top.sv`

## How to Change Colors

Edit the color generation section in `top.sv`:

```systemverilog
if (display_en) begin
    vga_r <= 4'hF;  // Red value (0x0 to 0xF)
    vga_g <= 4'h0;  // Green value (0x0 to 0xF)
    vga_b <= 4'h0;  // Blue value (0x0 to 0xF)
end
```

## Basic Colors

| Color   | R    | G    | B    | Hex Code      |
|---------|------|------|------|---------------|
| Black   | 4'h0 | 4'h0 | 4'h0 | #000          |
| White   | 4'hF | 4'hF | 4'hF | #FFF          |
| Red     | 4'hF | 4'h0 | 4'h0 | #F00 (default)|
| Green   | 4'h0 | 4'hF | 4'h0 | #0F0          |
| Blue    | 4'h0 | 4'h0 | 4'hF | #00F          |
| Yellow  | 4'hF | 4'hF | 4'h0 | #FF0          |
| Cyan    | 4'h0 | 4'hF | 4'hF | #0FF          |
| Magenta | 4'hF | 4'h0 | 4'hF | #F0F          |

## Intermediate Colors

| Color        | R    | G    | B    | Hex Code |
|--------------|------|------|------|----------|
| Orange       | 4'hF | 4'h8 | 4'h0 | #F80     |
| Pink         | 4'hF | 4'h8 | 4'h8 | #F88     |
| Purple       | 4'h8 | 4'h0 | 4'h8 | #808     |
| Lime         | 4'h8 | 4'hF | 4'h0 | #8F0     |
| Sky Blue     | 4'h0 | 4'h8 | 4'hF | #08F     |
| Brown        | 4'h8 | 4'h4 | 4'h0 | #840     |

## Gray Scale

| Color       | R    | G    | B    | Brightness |
|-------------|------|------|------|------------|
| Black       | 4'h0 | 4'h0 | 4'h0 | 0%         |
| Dark Gray   | 4'h4 | 4'h4 | 4'h4 | 27%        |
| Gray        | 4'h8 | 4'h8 | 4'h8 | 53%        |
| Light Gray  | 4'hC | 4'hC | 4'hC | 80%        |
| White       | 4'hF | 4'hF | 4'hF | 100%       |

## Pattern Ideas

### Vertical Stripes (8 colors)
```systemverilog
if (display_en) begin
    vga_r <= {4{hcount[7]}};
    vga_g <= {4{hcount[6]}};
    vga_b <= {4{hcount[5]}};
end
```

### Horizontal Stripes (8 colors)
```systemverilog
if (display_en) begin
    vga_r <= {4{vcount[7]}};
    vga_g <= {4{vcount[6]}};
    vga_b <= {4{vcount[5]}};
end
```

### Checkerboard (alternating red/blue)
```systemverilog
if (display_en) begin
    logic checker = hcount[5] ^ vcount[5];
    vga_r <= {4{checker}};
    vga_g <= 4'h0;
    vga_b <= {4{~checker}};
end
```

### Gradient (Red to Black, left to right)
```systemverilog
if (display_en) begin
    vga_r <= hcount[9:6];  // Use top 4 bits of hcount
    vga_g <= 4'h0;
    vga_b <= 4'h0;
end
```

### Rainbow Gradient (horizontal)
```systemverilog
if (display_en) begin
    logic [9:0] h = hcount;
    if (h < 213) begin      // 0-212: Red to Yellow
        vga_r <= 4'hF;
        vga_g <= h[9:6];
        vga_b <= 4'h0;
    end else if (h < 426) begin  // 213-425: Yellow to Green
        vga_r <= ~(h[9:6]);
        vga_g <= 4'hF;
        vga_b <= 4'h0;
    end else begin          // 426-639: Green to Blue
        vga_r <= 4'h0;
        vga_g <= ~(h[9:6]);
        vga_b <= 4'hF;
    end
end
```

### Color Bars (Test Pattern)
```systemverilog
if (display_en) begin
    // Divide screen into 8 vertical bars (640/8 = 80 pixels each)
    case (hcount[9:7])
        3'd0: {vga_r, vga_g, vga_b} = 12'hFFF; // White
        3'd1: {vga_r, vga_g, vga_b} = 12'hFF0; // Yellow
        3'd2: {vga_r, vga_g, vga_b} = 12'h0FF; // Cyan
        3'd3: {vga_r, vga_g, vga_b} = 12'h0F0; // Green
        3'd4: {vga_r, vga_g, vga_b} = 12'hF0F; // Magenta
        3'd5: {vga_r, vga_g, vga_b} = 12'hF00; // Red
        3'd6: {vga_r, vga_g, vga_b} = 12'h00F; // Blue
        3'd7: {vga_r, vga_g, vga_b} = 12'h000; // Black
    endcase
end
```

### Border (Red border, white center)
```systemverilog
if (display_en) begin
    logic border = (hcount < 10) || (hcount > 629) || 
                   (vcount < 10) || (vcount > 469);
    if (border) begin
        vga_r <= 4'hF;
        vga_g <= 4'h0;
        vga_b <= 4'h0;
    end else begin
        vga_r <= 4'hF;
        vga_g <= 4'hF;
        vga_b <= 4'hF;
    end
end
```

### Concentric Squares
```systemverilog
if (display_en) begin
    logic [9:0] x_dist = (hcount < 320) ? (320 - hcount) : (hcount - 320);
    logic [9:0] y_dist = (vcount < 240) ? (240 - vcount) : (vcount - 240);
    logic [9:0] max_dist = (x_dist > y_dist) ? x_dist : y_dist;
    vga_r <= max_dist[7:4];
    vga_g <= max_dist[6:3];
    vga_b <= max_dist[5:2];
end
```

## Understanding 4-bit Color

Each color channel has 4 bits = 16 levels (0-15)
- 0x0 = 0/15 = 0% brightness
- 0x8 = 8/15 = 53% brightness  
- 0xF = 15/15 = 100% brightness

Total color combinations: 16 × 16 × 16 = 4096 colors

## Voltage Output (R-2R DAC)

For a typical R-2R DAC with 0.7V full scale:
- 4'h0 = 0.000V (off)
- 4'h1 = 0.047V
- 4'h8 = 0.350V (half brightness)
- 4'hF = 0.700V (full brightness)

## Tips

1. **Start Simple**: Test with solid colors first
2. **Use Variables**: Define colors as localparam for readability
3. **Gradients**: Use upper bits of counters (e.g., hcount[9:6])
4. **Patterns**: XOR operations create nice patterns
5. **Regions**: Use if/else to divide screen into regions

## Color Definitions (Optional)

You can add these to `top.sv` for cleaner code:

```systemverilog
// Color definitions
localparam [11:0] COLOR_BLACK   = 12'h000;
localparam [11:0] COLOR_WHITE   = 12'hFFF;
localparam [11:0] COLOR_RED     = 12'hF00;
localparam [11:0] COLOR_GREEN   = 12'h0F0;
localparam [11:0] COLOR_BLUE    = 12'h00F;
localparam [11:0] COLOR_YELLOW  = 12'hFF0;
localparam [11:0] COLOR_CYAN    = 12'h0FF;
localparam [11:0] COLOR_MAGENTA = 12'hF0F;

// Use in code:
{vga_r, vga_g, vga_b} <= COLOR_CYAN;
```

## Experimentation

After getting the basic red screen working, try:
1. Change to different solid colors
2. Create vertical color bars
3. Add a border around the screen
4. Create a gradient
5. Implement a simple animation using frame_start signal

Have fun! 🎨
