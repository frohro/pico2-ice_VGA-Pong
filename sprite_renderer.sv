// Sprite Renderer Module
// Renders rectangular sprites (ball and paddle) for Pong game
// 
// Features:
// - Ball sprite: 16x16 pixel square (white)
// - Paddle sprite: 8x64 pixel rectangle (yellow)
// - Collision detection support

module sprite_renderer (
    input  logic        clk,
    input  logic        reset,
    
    // Current pixel position from VGA timing
    input  logic [9:0]  hcount,
    input  logic [9:0]  vcount,
    input  logic        display_en,
    
    // Ball position (center coordinates)
    input  logic [9:0]  ball_x,
    input  logic [9:0]  ball_y,
    
    // Paddle position (top-left coordinates)
    input  logic [9:0]  paddle_x,
    input  logic [9:0]  paddle_y,
    
    // RGB output
    output logic [3:0]  sprite_r,
    output logic [3:0]  sprite_g,
    output logic [3:0]  sprite_b,
    output logic        sprite_active
);

    // Sprite dimensions
    localparam BALL_SIZE   = 16;  // 16x16 square
    localparam PADDLE_W    = 8;   // 8 pixels wide
    localparam PADDLE_H    = 64;  // 64 pixels tall
    
    // Half sizes for center-based ball positioning
    localparam BALL_HALF   = BALL_SIZE / 2;
    
    logic ball_active;
    logic paddle_active;
    
    // Check if current pixel is within ball sprite
    always_comb begin
        ball_active = display_en &&
                      (hcount >= (ball_x - BALL_HALF)) &&
                      (hcount < (ball_x + BALL_HALF)) &&
                      (vcount >= (ball_y - BALL_HALF)) &&
                      (vcount < (ball_y + BALL_HALF));
    end
    
    // Check if current pixel is within paddle sprite
    always_comb begin
        paddle_active = display_en &&
                        (hcount >= paddle_x) &&
                        (hcount < (paddle_x + PADDLE_W)) &&
                        (vcount >= paddle_y) &&
                        (vcount < (paddle_y + PADDLE_H));
    end
    
    // Color generation
    // Ball is white (R=F, G=F, B=F)
    // Paddle is yellow (R=F, G=F, B=0)
    // Ball has priority over paddle
    always_ff @(posedge clk) begin
        if (reset) begin
            sprite_r      <= 4'h0;
            sprite_g      <= 4'h0;
            sprite_b      <= 4'h0;
            sprite_active <= 1'b0;
        end else begin
            sprite_active <= ball_active || paddle_active;
            
            if (ball_active) begin
                // White ball
                sprite_r <= 4'hF;
                sprite_g <= 4'hF;
                sprite_b <= 4'hF;
            end else if (paddle_active) begin
                // Yellow paddle
                sprite_r <= 4'hF;
                sprite_g <= 4'hF;
                sprite_b <= 4'h0;
            end else begin
                // Transparent (background shows through)
                sprite_r <= 4'h0;
                sprite_g <= 4'h0;
                sprite_b <= 4'h0;
            end
        end
    end

endmodule
