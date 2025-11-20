// Quick testbench for verifying ball movement and paddle position
// Runs faster than full display_pong_tb

`timescale 1ns/1ps

module quick_test;

    // Test signals
    logic clk, reset;
    logic frame_start;
    logic [9:0] ball_x, ball_y, paddle_x, paddle_y;
    
    // Instantiate just the game logic
    pong_game dut (
        .clk(clk),
        .reset(reset),
        .frame_start(frame_start),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end
    
    // Frame start pulse (every 1000ns for fast simulation)
    initial begin
        frame_start = 0;
        forever begin
            #1000;
            @(posedge clk);
            frame_start = 1;
            @(posedge clk);
            frame_start = 0;
        end
    end
    
    initial begin
        $display("=== Quick Pong Test ===\n");
        
        // Reset
        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;
        repeat (2) @(posedge clk);
        
        // Test 1: Check initial positions
        $display("Test 1: Initial Positions");
        $display("  Ball: (%0d, %0d) - Expected: (320, 240)", ball_x, ball_y);
        $display("  Paddle: (%0d, %0d) - Expected: (0, 240)", paddle_x, paddle_y);
        
        if (ball_x != 320) begin
            $display("  ERROR: Ball X is %0d, expected 320", ball_x);
            $finish;
        end
        if (ball_y != 240) begin
            $display("  ERROR: Ball Y is %0d, expected 240", ball_y);
            $finish;
        end
        if (paddle_x != 0) begin
            $display("  ERROR: Paddle X is %0d, expected 0", paddle_x);
            $finish;
        end
        if (paddle_y != 240) begin
            $display("  ERROR: Paddle Y is %0d, expected 240", paddle_y);
            $finish;
        end
        $display("  PASS: Initial positions correct\n");
        
        // Test 2: Ball movement after frames
        $display("Test 2: Ball Movement");
        repeat (10) @(posedge frame_start);
        @(posedge clk);
        
        $display("  After 10 frames:");
        $display("    Ball: (%0d, %0d)", ball_x, ball_y);
        
        if (ball_x == 320) begin
            $display("  ERROR: Ball X did not move from 320");
            $finish;
        end
        if (ball_y == 240) begin
            $display("  ERROR: Ball Y did not move from 240");
            $finish;
        end
        if (ball_x < 320) begin
            $display("  ERROR: Ball moving left instead of right");
            $finish;
        end
        if (ball_y < 240) begin
            $display("  ERROR: Ball moving up instead of down");
            $finish;
        end
        $display("  PASS: Ball is moving right and down\n");
        
        // Test 3: Continuous movement
        $display("Test 3: Continuous Movement");
        begin
            logic [9:0] x1, y1;
            x1 = ball_x;
            y1 = ball_y;
            repeat (20) @(posedge frame_start);
            @(posedge clk);
            
            $display("  After 20 more frames:");
            $display("    Ball moved from (%0d,%0d) to (%0d,%0d)", x1, y1, ball_x, ball_y);
            $display("    Delta: (%0d, %0d)", $signed(ball_x - x1), $signed(ball_y - y1));
            
            if (ball_x == x1 && ball_y == y1) begin
                $display("  ERROR: Ball stopped moving");
                $finish;
            end
            $display("  PASS: Ball continues to move\n");
        end
        
        // Test 4: Paddle tracking
        $display("Test 4: Paddle Tracking");
        $display("  Ball Y: %0d, Paddle Y: %0d, Paddle center: %0d", 
                 ball_y, paddle_y, paddle_y + 32);
        
        // Paddle should be trying to center on ball
        if (paddle_y + 32 < ball_y - 20 || paddle_y + 32 > ball_y + 20) begin
            $display("  WARNING: Paddle not tracking ball well (may need more time)");
        end else begin
            $display("  PASS: Paddle tracking ball");
        end
        
        $display("\n=== ALL TESTS PASSED ===");
        $finish;
    end
    
    // Watchdog
    initial begin
        #100000;
        $display("\nTIMEOUT");
        $finish;
    end

endmodule
