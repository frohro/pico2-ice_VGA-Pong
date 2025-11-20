// Testbench for display_pong wrapper
// Tests that the wrapper correctly generates frame_start and propagates positions

`timescale 1ns/1ps

module display_pong_tb;

    // Inputs
    logic clk;
    logic reset_in;
    
    // Outputs
    wire h_sync;
    wire v_sync;
    wire [11:0] rgb;
    
    // Instantiate DUT
    display_pong dut (
        .clk(clk),
        .reset_in(reset_in),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .rgb(rgb)
    );
    
    // Clock generation (50 MHz input)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 20ns period = 50 MHz
    end
    
    // Track internal signals
    integer frame_count;
    integer h_count, v_count;
    logic prev_h_sync, prev_v_sync;
    logic [9:0] ball_x_sample, ball_y_sample;
    logic [9:0] paddle_y_sample;
    integer frames_checked;
    
    // Monitor frame start signals
    integer frame_start_count;
    logic prev_frame_start;
    
    initial begin
        frame_start_count = 0;
        prev_frame_start = 0;
    end
    
    always @(posedge dut.clk_25) begin
        if (dut.frame_start && !prev_frame_start) begin
            frame_start_count++;
            $display("Time %0t: Frame start #%0d detected", $time, frame_start_count);
            $display("  Ball position: (%0d, %0d)", dut.ball_x, dut.ball_y);
            $display("  Paddle position: (%0d, %0d)", dut.paddle_x, dut.paddle_y);
        end
        prev_frame_start = dut.frame_start;
    end
    
    // Test stimulus
    initial begin
        $dumpfile("display_pong_tb.vcd");
        $dumpvars(0, display_pong_tb);
        
        // Initialize
        reset_in = 1;
        frame_count = 0;
        h_count = 0;
        v_count = 0;
        prev_h_sync = 1;
        prev_v_sync = 1;
        frames_checked = 0;
        
        $display("Starting display_pong testbench");
        $display("Expected: Ball at (320, 240), Paddle at (0, 240)");
        
        // Hold reset
        repeat (20) @(posedge clk);
        reset_in = 0;
        
        $display("\nTest 1: Check initial positions after reset");
        repeat (10) @(posedge dut.clk_25);
        
        $display("Initial - Ball: (%0d, %0d), Paddle: (%0d, %0d)", 
                 dut.ball_x, dut.ball_y, dut.paddle_x, dut.paddle_y);
        
        if (dut.ball_x != 320) $error("Ball X should be 320, got %0d", dut.ball_x);
        if (dut.ball_y != 240) $error("Ball Y should be 240, got %0d", dut.ball_y);
        if (dut.paddle_x != 0) $error("Paddle X should be 0, got %0d", dut.paddle_x);
        if (dut.paddle_y != 240) $error("Paddle Y should be 240, got %0d", dut.paddle_y);
        
        $display("\nTest 2: Wait for frame_start pulses and check ball movement");
        
        // Sample positions
        ball_x_sample = dut.ball_x;
        ball_y_sample = dut.ball_y;
        paddle_y_sample = dut.paddle_y;
        
        // Wait for 5 frame_start pulses
        repeat (5) begin
            @(posedge dut.frame_start);
            @(posedge dut.clk_25);  // Wait one cycle after frame_start
            frames_checked++;
        end
        
        // Give time for position update
        repeat (10) @(posedge dut.clk_25);
        
        $display("\nAfter %0d frames:", frames_checked);
        $display("  Previous - Ball: (%0d, %0d), Paddle Y: %0d", 
                 ball_x_sample, ball_y_sample, paddle_y_sample);
        $display("  Current  - Ball: (%0d, %0d), Paddle Y: %0d", 
                 dut.ball_x, dut.ball_y, dut.paddle_y);
        
        if (dut.ball_x == ball_x_sample) 
            $error("Ball X did not move! Still at %0d", dut.ball_x);
        else
            $display("  Ball X moved by %0d pixels", dut.ball_x - ball_x_sample);
            
        if (dut.ball_y == ball_y_sample) 
            $error("Ball Y did not move! Still at %0d", dut.ball_y);
        else
            $display("  Ball Y moved by %0d pixels", dut.ball_y - ball_y_sample);
        
        // Test that ball continues to move
        $display("\nTest 3: Verify continuous movement over 20 frames");
        ball_x_sample = dut.ball_x;
        ball_y_sample = dut.ball_y;
        
        repeat (20) begin
            @(posedge dut.frame_start);
            @(posedge dut.clk_25);
        end
        
        repeat (10) @(posedge dut.clk_25);
        
        $display("After 20 more frames:");
        $display("  Ball moved from (%0d, %0d) to (%0d, %0d)", 
                 ball_x_sample, ball_y_sample, dut.ball_x, dut.ball_y);
        $display("  Delta: (%0d, %0d)", 
                 $signed(dut.ball_x - ball_x_sample), 
                 $signed(dut.ball_y - ball_y_sample));
        
        if (dut.ball_x == ball_x_sample && dut.ball_y == ball_y_sample) begin
            $error("Ball is not moving!");
        end else begin
            $display("  Ball is moving correctly");
        end
        
        $display("\nTest 4: Check frame_start pulse characteristics");
        // Count how many cycles frame_start stays high
        begin
            integer pulse_width;
            @(posedge dut.frame_start);
                pulse_width = 0;
            while (dut.frame_start) begin
                pulse_width++;
                @(posedge dut.clk_25);
            end
            $display("frame_start pulse width: %0d cycles", pulse_width);
            if (pulse_width != 1) begin
                $error("frame_start should be single cycle pulse, got %0d cycles", pulse_width);
            end else begin
                $display("frame_start pulse is correct (1 cycle)");
            end
        end
        
        #10000;
        $display("\nAll display_pong tests completed!");
        $display("Total frame_start pulses seen: %0d", frame_start_count);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #50000000;  // 50ms
        $display("Simulation timeout");
        $finish;
    end

endmodule
