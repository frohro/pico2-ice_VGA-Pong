module test_init;
    localparam signed [25:0] INIT_BALL_X = 26'(320) << 16;
    localparam signed [25:0] INIT_BALL_Y = 26'(240) << 16;
    localparam signed [25:0] INIT_PADDLE_Y = 26'(240) << 16;
    
    initial begin
        $display("INIT_BALL_X = %h (%d integer part)", INIT_BALL_X, INIT_BALL_X[25:16]);
        $display("INIT_BALL_Y = %h (%d integer part)", INIT_BALL_Y, INIT_BALL_Y[25:16]);
        $display("INIT_PADDLE_Y = %h (%d integer part)", INIT_PADDLE_Y, INIT_PADDLE_Y[25:16]);
        $finish;
    end
endmodule
