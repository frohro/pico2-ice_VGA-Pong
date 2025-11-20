// Top-level module for VGA display on pico2-ice
// Pong game demo with ball and paddle sprites
//
// The RP2350B provides a 25 MHz clock to the FPGA via MicroPython ice.fpga() API
// (close to ideal 25.175 MHz - acceptable tolerance for VGA)
// VGA output uses 4 bits per color channel (R, G, B)
// connected to an R-2R DAC for analog conversion

module top (
    input  logic        clk_25mhz,    // 25 MHz clock from RP2350B
    input  logic        reset_n,      // Active low reset button
    
    // VGA outputs
    output logic [3:0]  vga_r,        // 4-bit red channel
    output logic [3:0]  vga_g,        // 4-bit green channel
    output logic [3:0]  vga_b,        // 4-bit blue channel
    output logic        vga_hsync,    // Horizontal sync
    output logic        vga_vsync,    // Vertical sync
    
    // Probe points for easier oscilloscope access
    output logic        vga_hsync_probe,
    output logic        vga_vsync_probe
);

    // Internal signals
    logic [9:0] hcount;
    logic [9:0] vcount;
    logic       display_en;
    logic       frame_start;
    logic       reset;
    
    // Game object positions
    logic [9:0] ball_x, ball_y;
    logic [9:0] paddle_x, paddle_y;
    
    // Sprite rendering signals
    logic [3:0] sprite_r, sprite_g, sprite_b;
    logic       sprite_active;
    
    // Convert active-low reset to active-high
    assign reset = ~reset_n;
    
    // Connect probe points to sync signals
    assign vga_hsync_probe = vga_hsync;
    assign vga_vsync_probe = vga_vsync;

    // Instantiate VGA timing generator
    vga_timing vga_timing_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .display_en(display_en),
        .frame_start(frame_start)
    );

    // Instantiate Pong game logic
    pong_game pong_game_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .frame_start(frame_start),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y)
    );

    // Instantiate sprite renderer
    sprite_renderer sprite_renderer_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .hcount(hcount),
        .vcount(vcount),
        .display_en(display_en),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y),
        .sprite_r(sprite_r),
        .sprite_g(sprite_g),
        .sprite_b(sprite_b),
        .sprite_active(sprite_active)
    );

    // Color generation logic
    // Composite sprites over red background
    always_ff @(posedge clk_25mhz or posedge reset) begin
        if (reset) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end else begin
            if (display_en) begin
                if (sprite_active) begin
                    // Display sprite colors (ball or paddle)
                    vga_r <= sprite_r;
                    vga_g <= sprite_g;
                    vga_b <= sprite_b;
                end else begin
                    // Red background
                    vga_r <= 4'hF;
                    vga_g <= 4'h0;
                    vga_b <= 4'h0;
                end
            end else begin
                // Black during blanking period
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
        end
    end

endmodule
