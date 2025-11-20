// Display wrapper for Pong game VGA simulation
// Interfaces the Pong design with the VGA simulator

`timescale 1ns / 1ps

module display_pong(
    input wire clk,          // 50MHz input clock for simulator
    input wire reset_in,     // Active high reset input
    output wire h_sync,      // Horizontal sync
    output wire v_sync,      // Vertical sync
    output wire [11:0] rgb   // 12-bit RGB output (4 bits per channel)
);
    
    // Internal signals
    wire clk_25;
    reg reset_sync;
    wire [9:0] hcount, vcount;
    wire display_en;
    wire frame_start;
    wire [3:0] vga_r, vga_g, vga_b;
    
    // Game object positions
    wire [9:0] ball_x, ball_y;
    wire [9:0] paddle_x, paddle_y;
    
    // Sprite rendering signals
    wire [3:0] sprite_r, sprite_g, sprite_b;
    wire sprite_active;
    
    // Generate 25MHz clock from 50MHz input
    reg clk_div;
    always @(posedge clk) begin
        if (reset_in)
            clk_div <= 1'b0;
        else
            clk_div <= ~clk_div;
    end
    assign clk_25 = clk_div;
    
    // Synchronize reset to 25MHz clock domain
    always @(posedge clk_25) begin
        reset_sync <= reset_in;
    end
    
    // VGA timing parameters (matching the Pong design)
    localparam H_VISIBLE   = 640;
    localparam H_FRONT     = 16;
    localparam H_SYNC      = 96;
    localparam H_BACK      = 48;
    localparam H_TOTAL     = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800
    
    localparam V_VISIBLE   = 480;
    localparam V_FRONT     = 10;
    localparam V_SYNC      = 2;
    localparam V_BACK      = 33;
    localparam V_TOTAL     = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525
    
    localparam H_SYNC_START = H_VISIBLE + H_FRONT;           // 656
    localparam H_SYNC_END   = H_VISIBLE + H_FRONT + H_SYNC; // 752
    localparam V_SYNC_START = V_VISIBLE + V_FRONT;           // 490
    localparam V_SYNC_END   = V_VISIBLE + V_FRONT + V_SYNC; // 492
    
    // Counters
    reg [9:0] h_count_reg, v_count_reg;
    
    always @(posedge clk_25) begin
        if (reset_sync) begin
            h_count_reg <= 10'd0;
            v_count_reg <= 10'd0;
        end else begin
            if (h_count_reg == H_TOTAL - 1) begin
                h_count_reg <= 10'd0;
                if (v_count_reg == V_TOTAL - 1)
                    v_count_reg <= 10'd0;
                else
                    v_count_reg <= v_count_reg + 10'd1;
            end else begin
                h_count_reg <= h_count_reg + 10'd1;
            end
        end
    end
    
    assign hcount = h_count_reg;
    assign vcount = v_count_reg;
    
    // Generate sync signals (negative polarity)
    reg h_sync_reg, v_sync_reg;
    always @(posedge clk_25) begin
        if (reset_sync) begin
            h_sync_reg <= 1'b1;
            v_sync_reg <= 1'b1;
        end else begin
            h_sync_reg <= ~((h_count_reg >= H_SYNC_START) && (h_count_reg < H_SYNC_END));
            v_sync_reg <= ~((v_count_reg >= V_SYNC_START) && (v_count_reg < V_SYNC_END));
        end
    end
    
    assign h_sync = h_sync_reg;
    assign v_sync = v_sync_reg;
    
    // Display enable
    reg display_en_reg;
    always @(posedge clk_25) begin
        if (reset_sync)
            display_en_reg <= 1'b0;
        else
            display_en_reg <= (h_count_reg < H_VISIBLE) && (v_count_reg < V_VISIBLE);
    end
    assign display_en = display_en_reg;
    
    // Frame start pulse - single cycle pulse at start of frame
    // Pulse when counters are at (0,0)
    assign frame_start = (h_count_reg == 10'd0) && (v_count_reg == 10'd0);
    
    // Instantiate Pong game logic
    pong_game pong_game_inst (
        .clk(clk_25),
        .reset(reset_sync),
        .frame_start(frame_start),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y)
    );
    
    // Instantiate sprite renderer
    sprite_renderer sprite_renderer_inst (
        .clk(clk_25),
        .reset(reset_sync),
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
    
    // Color generation logic - composite sprites over red background
    reg [3:0] r_reg, g_reg, b_reg;
    always @(posedge clk_25) begin
        if (reset_sync) begin
            r_reg <= 4'h0;
            g_reg <= 4'h0;
            b_reg <= 4'h0;
        end else begin
            if (display_en) begin
                if (sprite_active) begin
                    // Display sprite colors (ball or paddle)
                    r_reg <= sprite_r;
                    g_reg <= sprite_g;
                    b_reg <= sprite_b;
                end else begin
                    // Red background
                    r_reg <= 4'hF;
                    g_reg <= 4'h0;
                    b_reg <= 4'h0;
                end
            end else begin
                // Black during blanking period
                r_reg <= 4'h0;
                g_reg <= 4'h0;
                b_reg <= 4'h0;
            end
        end
    end
    
    assign vga_r = r_reg;
    assign vga_g = g_reg;
    assign vga_b = b_reg;
    
    // Output RGB (12-bit total)
    assign rgb = {vga_r, vga_g, vga_b};

endmodule
