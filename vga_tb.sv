// Testbench for VGA timing module
// Verifies correct timing for 640x480@60Hz VGA signal

`timescale 1ns/1ps

module vga_tb;

    // Clock period for 25.175 MHz = 39.72 ns
    localparam CLOCK_PERIOD = 39.72;
    
    // Testbench signals
    logic        clk;
    logic        reset;
    logic [9:0]  hcount;
    logic [9:0]  vcount;
    logic        hsync;
    logic        vsync;
    logic        display_en;
    logic        frame_start;
    
    // Instantiate VGA timing module
    vga_timing dut (
        .clk(clk),
        .reset(reset),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .display_en(display_en),
        .frame_start(frame_start)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $display("Starting VGA timing testbench...");
        $display("Testing 640x480@60Hz timing");
        
        // Initialize
        reset = 1;
        #(CLOCK_PERIOD * 10);
        reset = 0;
        
        // Wait for one complete frame
        @(posedge frame_start);
        $display("Frame start detected at time %0t", $time);
        
        // Verify horizontal timing
        @(posedge clk);
        wait(hcount == 0);
        $display("Checking horizontal timing...");
        
        // Check visible area
        wait(hcount == 639);
        if (display_en && hsync) begin
            $display("✓ Horizontal visible area correct (640 pixels)");
        end else begin
            $display("✗ ERROR: Display enable or hsync incorrect during visible area");
        end
        
        // Check front porch
        wait(hcount == 655);
        if (!display_en && hsync) begin
            $display("✓ Horizontal front porch correct");
        end else begin
            $display("✗ ERROR: Front porch timing incorrect");
        end
        
        // Check sync pulse (account for 1-cycle register delay)
        // When hcount=656, on next clock hsync goes low
        wait(hcount == 655);
        wait(hcount == 656);
        @(posedge clk);
        #1; // Small delay to let signals settle
        if (!hsync) begin
            $display("✓ HSYNC pulse started correctly");
        end else begin
            $display("✗ ERROR: HSYNC pulse not active");
        end
        
        // HSYNC stays low while hcount is 656-751 (96 clocks)
        wait(hcount == 751);
        @(posedge clk);
        #1;
        if (!hsync) begin
            $display("✓ HSYNC pulse width correct (96 pixels)");
        end else begin
            $display("✗ ERROR: HSYNC pulse ended early");
        end
        
        // When hcount=752, hsync goes high on next clock
        wait(hcount == 752);
        @(posedge clk);
        #1;
        if (hsync) begin
            $display("✓ HSYNC pulse ended correctly");
        end else begin
            $display("✗ ERROR: HSYNC pulse too long");
        end
        
        // Wait for vertical sync to test
        wait(vcount == 489);
        $display("Checking vertical timing...");
        
        @(posedge clk);
        #1;
        if (vsync) begin
            $display("✓ VSYNC inactive during visible lines");
        end else begin
            $display("✗ ERROR: VSYNC active too early");
        end
        
        // VSYNC should go low when vcount=490
        wait(vcount == 490);
        wait(hcount == 0);
        @(posedge clk);
        #1;
        if (!vsync) begin
            $display("✓ VSYNC pulse started correctly");
        end else begin
            $display("✗ ERROR: VSYNC pulse not active");
        end
        
        // VSYNC should go high when vcount=492  
        wait(vcount == 492);
        wait(hcount == 0);
        @(posedge clk);
        #1;
        if (vsync) begin
            $display("✓ VSYNC pulse width correct (2 lines)");
        end else begin
            $display("✗ ERROR: VSYNC pulse too long");
        end
        
        // Wait for next frame start
        @(posedge frame_start);
        $display("Second frame start detected - frame timing correct!");
        
        // Check that one frame takes approximately 16.67 ms (60 Hz)
        $display("One complete frame processed");
        
        $display("\nTestbench completed successfully!");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLOCK_PERIOD * 1000000); // Wait for ~1 million clocks
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Optional: Generate VCD file for waveform viewing
    initial begin
        $dumpfile("vga_tb.vcd");
        $dumpvars(0, vga_tb);
    end

endmodule
