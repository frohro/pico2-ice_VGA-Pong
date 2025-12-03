// Quick debug test to check positions
#include <iostream>
#include <verilated.h>
#include "Vdisplay_pong_debug.h"

int main() {
    Vdisplay_pong_debug* dut = new Vdisplay_pong_debug;
    
    std::cout << "=== Position Debug Test ===\n\n";
    
    // Reset
    dut->clk = 0;
    dut->reset_in = 1;
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
    }
    dut->reset_in = 0;
    
    // Run a bit after reset
    for (int i = 0; i < 100; i++) {
        dut->clk = !dut->clk;
        dut->eval();
    }
    
    std::cout << "After reset (should be at initial positions):\n";
    std::cout << "  Ball X: " << (int)dut->debug_ball_x << " (expected: 320)\n";
    std::cout << "  Ball Y: " << (int)dut->debug_ball_y << " (expected: 240)\n";
    std::cout << "  Paddle X: " << (int)dut->debug_paddle_x << " (expected: 0)\n";
    std::cout << "  Paddle Y: " << (int)dut->debug_paddle_y << " (expected: 240)\n\n";
    
    // Wait for several frame_start pulses
    int frames = 0;
    int prev_ball_x = dut->debug_ball_x;
    int prev_ball_y = dut->debug_ball_y;
    bool prev_frame_start = false;
    
    std::cout << "Waiting for 10 frames...\n";
    for (int cycle = 0; cycle < 5000000 && frames < 10; cycle++) {
        dut->clk = 0;
        dut->eval();
        dut->clk = 1;
        dut->eval();
        
        // Detect frame_start pulse
        if (dut->debug_frame_start && !prev_frame_start) {
            frames++;
            std::cout << "Frame " << frames << ": Ball=(" 
                      << (int)dut->debug_ball_x << "," << (int)dut->debug_ball_y 
                      << "), Paddle Y=" << (int)dut->debug_paddle_y << "\n";
        }
        prev_frame_start = dut->debug_frame_start;
    }
    
    std::cout << "\nAfter " << frames << " frames:\n";
    std::cout << "  Ball moved from (" << prev_ball_x << "," << prev_ball_y 
              << ") to (" << (int)dut->debug_ball_x << "," << (int)dut->debug_ball_y << ")\n";
    std::cout << "  Delta: (" << ((int)dut->debug_ball_x - prev_ball_x) << "," 
              << ((int)dut->debug_ball_y - prev_ball_y) << ")\n";
    
    if (dut->debug_ball_x == prev_ball_x && dut->debug_ball_y == prev_ball_y) {
        std::cout << "  ERROR: Ball did not move!\n";
    } else {
        std::cout << "  OK: Ball is moving\n";
    }
    
    delete dut;
    return 0;
}
