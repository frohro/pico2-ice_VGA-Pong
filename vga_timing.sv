// VGA Timing Generator Module
// Generates VGA sync signals for 640x480 @ 60Hz
// Pixel clock: 25.175 MHz
//
// Timing specifications from http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html
// 
// Horizontal timing (in pixels):
//   - Visible area: 640 pixels (D)
//   - Front porch: 16 pixels (E)
//   - Sync pulse: 96 pixels (B)
//   - Back porch: 48 pixels (C)
//   - Total: 800 pixels (A)
//
// Vertical timing (in lines):
//   - Visible area: 480 lines (R)
//   - Front porch: 10 lines (S)
//   - Sync pulse: 2 lines (P)
//   - Back porch: 33 lines (Q)
//   - Total: 525 lines (O)
//
// Both HSYNC and VSYNC are negative polarity for 640x480@60Hz

module vga_timing (
    input  logic        clk,          // 25.175 MHz pixel clock
    input  logic        reset,        // Active high reset
    output logic [9:0]  hcount,       // Horizontal pixel counter (0-799)
    output logic [9:0]  vcount,       // Vertical line counter (0-524)
    output logic        hsync,        // Horizontal sync (negative polarity)
    output logic        vsync,        // Vertical sync (negative polarity)
    output logic        display_en,   // Display enable (high during visible area)
    output logic        frame_start   // Pulse at start of new frame
);

    // Horizontal timing constants (in pixels)
    localparam H_VISIBLE   = 640;
    localparam H_FRONT     = 16;
    localparam H_SYNC      = 96;
    localparam H_BACK      = 48;
    localparam H_TOTAL     = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800
    
    // Vertical timing constants (in lines)
    localparam V_VISIBLE   = 480;
    localparam V_FRONT     = 10;
    localparam V_SYNC      = 2;
    localparam V_BACK      = 33;
    localparam V_TOTAL     = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525
    
    // Sync pulse boundaries
    localparam H_SYNC_START = H_VISIBLE + H_FRONT;           // 656
    localparam H_SYNC_END   = H_VISIBLE + H_FRONT + H_SYNC; // 752
    localparam V_SYNC_START = V_VISIBLE + V_FRONT;           // 490
    localparam V_SYNC_END   = V_VISIBLE + V_FRONT + V_SYNC; // 492

    // Counters
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            hcount <= 10'd0;
            vcount <= 10'd0;
        end else begin
            // Horizontal counter
            if (hcount == H_TOTAL - 1) begin
                hcount <= 10'd0;
                
                // Vertical counter
                if (vcount == V_TOTAL - 1) begin
                    vcount <= 10'd0;
                end else begin
                    vcount <= vcount + 10'd1;
                end
            end else begin
                hcount <= hcount + 10'd1;
            end
        end
    end

    // Generate sync signals (negative polarity for 640x480@60Hz)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1;  // Inactive (high) when reset
            vsync <= 1'b1;  // Inactive (high) when reset
        end else begin
            // HSYNC is low during sync pulse (negative polarity)
            hsync <= ~((hcount >= H_SYNC_START) && (hcount < H_SYNC_END));
            
            // VSYNC is low during sync pulse (negative polarity)
            vsync <= ~((vcount >= V_SYNC_START) && (vcount < V_SYNC_END));
        end
    end

    // Display enable signal (high during visible area)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            display_en <= 1'b0;
        end else begin
            display_en <= (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
        end
    end

    // Frame start pulse (one clock cycle at start of new frame)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            frame_start <= 1'b0;
        end else begin
            frame_start <= (hcount == 10'd0) && (vcount == 10'd0);
        end
    end

endmodule
