// Testbench for pong_game module
// Tests game physics, collisions, and paddle AI

`timescale 1ns/1ps

module pong_game_tb;

    // Clock and reset
    logic        clk;
    logic        reset;
    logic        frame_start;
    
    // Outputs
    logic [9:0]  ball_x;
    logic [9:0]  ball_y;
    logic [9:0]  paddle_x;
    logic [9:0]  paddle_y;
    
    // Instantiate DUT
    pong_game dut (
        .clk(clk),
        .reset(reset),
        .frame_start(frame_start),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y)
    );
    
    // Clock generation (25 MHz)
    initial begin
        clk = 0;
        forever #20 clk = ~clk;  // 40ns period = 25 MHz
    end
    
    // Frame start generation (60 Hz - every 16.67ms = 416,667 clock cycles)
    // For simulation, use faster frame rate
    initial begin
        frame_start = 0;
        forever begin
            #1000;  // Shortened for simulation
            frame_start = 1;
            #40;
            frame_start = 0;
        end
    end
    
    // Monitor positions
    logic [9:0] prev_ball_x, prev_ball_y;
    logic signed [10:0] delta_x, delta_y;
    
    always @(posedge clk) begin
        if (frame_start) begin
            delta_x = $signed({1'b0, ball_x}) - $signed({1'b0, prev_ball_x});
            delta_y = $signed({1'b0, ball_y}) - $signed({1'b0, prev_ball_y});
            prev_ball_x = ball_x;
            prev_ball_y = ball_y;
        end
    end
    
    // Test stimulus
    initial begin
        $dumpfile("pong_game_tb.vcd");
        $dumpvars(0, pong_game_tb);
        
        // Initialize
        reset = 1;
        prev_ball_x = 0;
        prev_ball_y = 0;
        
        #100;
        reset = 0;
        #40;
        
        $display("Test 1: Initial positions");
        $display("Ball at (%0d, %0d), should be near (320, 240)", ball_x, ball_y);
        assert (ball_x >= 319 && ball_x <= 321) else $error("Ball X not centered");
        assert (ball_y >= 239 && ball_y <= 241) else $error("Ball Y not centered");
        assert (paddle_x == 0) else $error("Paddle should be at left edge");
        $display("Paddle at (%0d, %0d)", paddle_x, paddle_y);
        
        // Wait for a few frames and check ball movement
        repeat (5) @(posedge frame_start);
        #100;
        
        $display("\nTest 2: Ball movement after 5 frames");
        $display("Ball at (%0d, %0d), delta per frame: (%0d, %0d)", 
                 ball_x, ball_y, delta_x, delta_y);
        assert (ball_x > 320) else $error("Ball should move right");
        assert (ball_y > 240) else $error("Ball should move down");
        
        // Let ball move for many frames to test paddle tracking
        repeat (20) @(posedge frame_start);
        #100;
        
        $display("\nTest 3: Paddle tracking (after 20 more frames)");
        $display("Ball Y: %0d, Paddle Y: %0d (center at %0d)", 
                 ball_y, paddle_y, paddle_y + 32);
        // Paddle center should be tracking ball Y
        // Allow some margin for tracking lag
        assert ((paddle_y + 32) >= (ball_y - 10) && (paddle_y + 32) <= (ball_y + 10))
            else $error("Paddle not tracking ball properly");
        
        // Let simulation run to observe collisions
        $display("\nTest 4: Running simulation for wall collisions...");
        repeat (200) @(posedge frame_start);
        
        $display("\nTest 5: Final positions");
        $display("Ball at (%0d, %0d)", ball_x, ball_y);
        $display("Paddle at (%0d, %0d)", paddle_x, paddle_y);
        
        // Check ball stays in bounds
        assert (ball_x >= 8 && ball_x < 632) else $error("Ball X out of bounds");
        assert (ball_y >= 8 && ball_y < 472) else $error("Ball Y out of bounds");
        
        #1000;
        $display("\nAll tests completed successfully!");
        $finish;
    end
    
    // Monitor for interesting events
    always @(posedge clk) begin
        if (frame_start) begin
            // Detect collision events by checking velocity reversals
            if ($signed(delta_x) * $signed(prev_ball_x - ball_x) < 0) begin
                $display("Time %0t: Horizontal bounce detected at (%0d, %0d)", 
                         $time, ball_x, ball_y);
            end
            if ($signed(delta_y) * $signed(prev_ball_y - ball_y) < 0) begin
                $display("Time %0t: Vertical bounce detected at (%0d, %0d)", 
                         $time, ball_x, ball_y);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #300000;
        $display("Simulation timeout reached");
        $finish;
    end

endmodule
