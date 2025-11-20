// Debug wrapper for display_pong that exposes internal signals
// Used to verify ball and paddle positions

module display_pong_debug(
    input wire clk,
    input wire reset_in,
    output wire h_sync,
    output wire v_sync,
    output wire [11:0] rgb,
    // Debug outputs
    output wire [9:0] debug_ball_x,
    output wire [9:0] debug_ball_y,
    output wire [9:0] debug_paddle_x,
    output wire [9:0] debug_paddle_y,
    output wire debug_frame_start
);

    // Internal signals
    wire [9:0] ball_x, ball_y;
    wire [9:0] paddle_x, paddle_y;
    wire frame_start;
    
    // Instantiate the real design
    display_pong dut (
        .clk(clk),
        .reset_in(reset_in),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .rgb(rgb)
    );
    
    // Expose internal signals
    assign debug_ball_x = dut.ball_x;
    assign debug_ball_y = dut.ball_y;
    assign debug_paddle_x = dut.paddle_x;
    assign debug_paddle_y = dut.paddle_y;
    assign debug_frame_start = dut.frame_start;

endmodule
