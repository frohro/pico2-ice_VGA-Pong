// Pong Game Logic Module
// Implements ball physics, paddle AI, and collision detection
// 
// Ball velocity: 100 pixels/second horizontal, 50 pixels/second vertical
// At 60 Hz frame rate: ~1.67 pixels/frame horizontal, ~0.83 pixels/frame vertical
// Using fixed-point arithmetic: velocity stored as pixels * 2^16 per frame

module pong_game (
    input  logic        clk,
    input  logic        reset,
    input  logic        frame_start,  // Pulse at start of each frame
    
    // Ball position output (center coordinates)
    output logic [9:0]  ball_x,
    output logic [9:0]  ball_y,
    
    // Paddle position output (top-left coordinates)
    output logic [9:0]  paddle_x,
    output logic [9:0]  paddle_y
);

    // Screen dimensions
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;
    
    // Sprite dimensions
    localparam BALL_SIZE   = 16;
    localparam BALL_HALF   = BALL_SIZE / 2;
    localparam PADDLE_W    = 8;
    localparam PADDLE_H    = 64;
    localparam PADDLE_HALF_H = PADDLE_H / 2;
    
    // Game speed parameters (pixels per second)
    localparam BALL_SPEED_H = 400;  // Horizontal speed (pixels/sec)
    localparam BALL_SPEED_V = 200;  // Vertical speed (pixels/sec)
    localparam PADDLE_SPEED_VAL = 200;  // Paddle tracking speed (pixels/sec)
    
    // Fixed-point format: 10.16 (10 integer bits, 16 fractional bits)
    // Convert pixels/sec to pixels/frame at 60 Hz
    // Formula: (pixels_per_sec * 65536) / 60
    localparam signed [25:0] BALL_VEL_H = (BALL_SPEED_H * 65536) / 60;
    localparam signed [25:0] BALL_VEL_V = (BALL_SPEED_V * 65536) / 60;
    localparam signed [25:0] PADDLE_SPEED = (PADDLE_SPEED_VAL * 65536) / 60;
    
    // Initialize ball at center of screen
    localparam signed [25:0] INIT_BALL_X = 26'(SCREEN_W / 2) << 16;
    localparam signed [25:0] INIT_BALL_Y = 26'(SCREEN_H / 2) << 16;
    localparam signed [25:0] INIT_PADDLE_Y = 26'(240) << 16;  // Start paddle at Y=240
    
    // Ball position and velocity (fixed-point 10.16)
    /* verilator lint_off PROCASSINIT */
    logic signed [25:0] ball_x_fp = INIT_BALL_X;
    logic signed [25:0] ball_y_fp = INIT_BALL_Y;
    logic signed [25:0] ball_vx_fp = BALL_VEL_H;
    logic signed [25:0] ball_vy_fp = BALL_VEL_V;
    
    // Paddle position (fixed-point 10.16)
    logic signed [25:0] paddle_y_fp = INIT_PADDLE_Y;
    /* verilator lint_on PROCASSINIT */
    
    // Temporary calculation variables
    logic signed [25:0] next_x, next_y;
    logic [9:0] ball_x_int, ball_y_int;
    logic hit_left, hit_right, hit_top, hit_bottom, hit_paddle;
    logic signed [25:0] target_paddle_y;
    logic signed [25:0] paddle_error;
    
    /* verilator lint_off BLKSEQ */
    // Ball position update and collision detection
    always_ff @(posedge clk) begin
        if (reset) begin
            ball_x_fp  <= INIT_BALL_X;
            ball_y_fp  <= INIT_BALL_Y;
            ball_vx_fp <= BALL_VEL_H;   // Start moving right
            ball_vy_fp <= BALL_VEL_V;    // Start moving down
            paddle_y_fp <= INIT_PADDLE_Y;
        end else if (frame_start) begin
            
            // Calculate next position
            next_x = ball_x_fp + ball_vx_fp;
            next_y = ball_y_fp + ball_vy_fp;
            
            // Extract integer parts for collision detection
            ball_x_int = ball_x_fp[25:16];
            ball_y_int = ball_y_fp[25:16];
            
            // Collision detection
            hit_left   = (ball_x_int <= BALL_HALF + PADDLE_W);
            hit_right  = (ball_x_int >= SCREEN_W - BALL_HALF);
            hit_top    = (ball_y_int <= BALL_HALF);
            hit_bottom = (ball_y_int >= SCREEN_H - BALL_HALF);
            
            // Paddle collision (check if ball is at paddle X and within paddle Y range)
            hit_paddle = hit_left && 
                         (ball_y_int >= (paddle_y_fp[25:16])) &&
                         (ball_y_int <= (paddle_y_fp[25:16] + PADDLE_H));
            
            // Horizontal collision handling
            if (hit_paddle && ball_vx_fp < 0) begin
                // Bounce off paddle (only if moving left)
                ball_vx_fp <= -ball_vx_fp;
                ball_x_fp  <= 26'((PADDLE_W + BALL_HALF + 1) << 16);  // Position just after paddle
            end else if (hit_left && ball_vx_fp < 0) begin
                // Bounce off left wall (only if moving left)
                ball_vx_fp <= -ball_vx_fp;
                ball_x_fp  <= 26'((BALL_HALF + 1) << 16);
            end else if (hit_right && ball_vx_fp > 0) begin
                // Bounce off right wall (only if moving right)
                ball_vx_fp <= -ball_vx_fp;
                ball_x_fp  <= 26'((SCREEN_W - BALL_HALF - 1) << 16);
            end else begin
                ball_x_fp <= next_x;
            end
            
            // Vertical collision handling
            if (hit_top && ball_vy_fp < 0) begin
                // Bounce off top (only if moving up)
                ball_vy_fp <= -ball_vy_fp;
                ball_y_fp  <= 26'((BALL_HALF + 1) << 16);
            end else if (hit_bottom && ball_vy_fp > 0) begin
                // Bounce off bottom (only if moving down)
                ball_vy_fp <= -ball_vy_fp;
                ball_y_fp  <= 26'((SCREEN_H - BALL_HALF - 1) << 16);
            end else begin
                ball_y_fp <= next_y;
            end
            
            // Paddle AI: Track ball's vertical position
            // Move paddle center to ball's Y position
            // Target: align paddle center with ball Y
            target_paddle_y = ball_y_fp - 26'(PADDLE_HALF_H << 16);
            
            // Clamp target to screen bounds BEFORE calculating movement
            if (target_paddle_y < 0) begin
                target_paddle_y = 26'h0;
            end else if (target_paddle_y > 26'((SCREEN_H - PADDLE_H) << 16)) begin
                target_paddle_y = 26'((SCREEN_H - PADDLE_H) << 16);
            end
            
            paddle_error = target_paddle_y - paddle_y_fp;
            
            // Move paddle towards target with speed limit
            if (paddle_error > PADDLE_SPEED) begin
                paddle_y_fp <= paddle_y_fp + PADDLE_SPEED;
            end else if (paddle_error < -PADDLE_SPEED) begin
                paddle_y_fp <= paddle_y_fp - PADDLE_SPEED;
            end else begin
                paddle_y_fp <= target_paddle_y;
            end
        end
    end
    /* verilator lint_on BLKSEQ */
    
    // Output integer positions
    assign ball_x = ball_x_fp[25:16];
    assign ball_y = ball_y_fp[25:16];
    assign paddle_x = 10'd0;  // Paddle always at left edge
    assign paddle_y = paddle_y_fp[25:16];

endmodule
