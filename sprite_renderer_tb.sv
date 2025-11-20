// Testbench for sprite_renderer module
// Tests sprite rendering for ball and paddle

`timescale 1ns/1ps

module sprite_renderer_tb;

    // Clock and reset
    logic        clk;
    logic        reset;
    
    // VGA timing inputs
    logic [9:0]  hcount;
    logic [9:0]  vcount;
    logic        display_en;
    
    // Sprite positions
    logic [9:0]  ball_x;
    logic [9:0]  ball_y;
    logic [9:0]  paddle_x;
    logic [9:0]  paddle_y;
    
    // Outputs
    logic [3:0]  sprite_r;
    logic [3:0]  sprite_g;
    logic [3:0]  sprite_b;
    logic        sprite_active;
    
    // Instantiate DUT
    sprite_renderer dut (
        .clk(clk),
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
    
    // Clock generation (25 MHz)
    initial begin
        clk = 0;
        forever #20 clk = ~clk;  // 40ns period = 25 MHz
    end
    
    // Test stimulus
    initial begin
        $dumpfile("sprite_renderer_tb.vcd");
        $dumpvars(0, sprite_renderer_tb);
        
        // Initialize
        reset = 1;
        hcount = 0;
        vcount = 0;
        display_en = 0;
        ball_x = 320;    // Center of screen
        ball_y = 240;
        paddle_x = 0;    // Left edge
        paddle_y = 208;  // Centered (240 - 32)
        
        #100;
        reset = 0;
        #40;
        
        // Test 1: Background pixel (no sprite)
        $display("Test 1: Background pixel");
        display_en = 1;
        hcount = 100;
        vcount = 100;
        #40;
        assert (sprite_active == 0) else $error("Sprite should not be active");
        
        // Test 2: Ball sprite (center pixel)
        $display("Test 2: Ball sprite center");
        hcount = 320;
        vcount = 240;
        #40;
        assert (sprite_active == 1) else $error("Sprite should be active for ball");
        assert (sprite_r == 4'hF && sprite_g == 4'hF && sprite_b == 4'hF) 
            else $error("Ball should be white");
        
        // Test 3: Ball sprite edge
        $display("Test 3: Ball sprite edge");
        hcount = 320 + 7;  // Right edge of ball (within 16x16)
        vcount = 240;
        #40;
        assert (sprite_active == 1) else $error("Sprite should be active at ball edge");
        
        // Test 4: Just outside ball
        $display("Test 4: Outside ball");
        hcount = 320 + 8;  // Just outside ball
        vcount = 240;
        #40;
        assert (sprite_active == 0) else $error("Sprite should not be active outside ball");
        
        // Test 5: Paddle sprite
        $display("Test 5: Paddle sprite");
        hcount = 4;      // Within paddle X (0-7)
        vcount = 240;    // Within paddle Y (208-271)
        #40;
        assert (sprite_active == 1) else $error("Sprite should be active for paddle");
        assert (sprite_r == 4'hF && sprite_g == 4'hF && sprite_b == 4'h0) 
            else $error("Paddle should be yellow");
        
        // Test 6: Paddle edge
        $display("Test 6: Paddle edge");
        hcount = 7;      // Right edge of paddle
        vcount = 271;    // Bottom edge of paddle
        #40;
        assert (sprite_active == 1) else $error("Sprite should be active at paddle edge");
        
        // Test 7: Just outside paddle
        $display("Test 7: Outside paddle");
        hcount = 8;      // Just outside paddle
        vcount = 240;
        #40;
        assert (sprite_active == 0) else $error("Sprite should not be active outside paddle");
        
        // Test 8: Display disabled
        $display("Test 8: Display disabled");
        display_en = 0;
        hcount = 320;
        vcount = 240;
        #40;
        assert (sprite_active == 0) else $error("Sprite should not be active when display disabled");
        
        // Test 9: Ball and paddle overlap (ball priority)
        $display("Test 9: Ball over paddle");
        display_en = 1;
        ball_x = 16;     // Position ball over paddle (avoiding underflow)
        ball_y = 240;
        paddle_x = 0;
        paddle_y = 208;
        hcount = 10;     // Within ball range (16-8 to 16+8 = 8 to 24)
        vcount = 240;
        #80;  // Need extra time for position update to propagate
        assert (sprite_active == 1) else $error("Sprite should be active");
        assert (sprite_r == 4'hF && sprite_g == 4'hF && sprite_b == 4'hF) 
            else $error("Ball should have priority (white), got R=%h G=%h B=%h", sprite_r, sprite_g, sprite_b);
        
        #100;
        $display("All tests completed successfully!");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
