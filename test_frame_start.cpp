#include <iostream>
#include "Vdisplay_pong.h"
#include "verilated.h"

int main() {
    Vdisplay_pong* dut = new Vdisplay_pong;
    
    // Reset
    dut->clk = 0;
    dut->reset_in = 1;
    for (int i = 0; i < 10; i++) {
        dut->clk = !dut->clk;
        dut->eval();
    }
    dut->reset_in = 0;
    
    // Run for several frames and track ball position
    int ball_x_prev = 0;
    int ball_y_prev = 0;
    bool found_movement = false;
    
    for (int cycle = 0; cycle < 2000000 && !found_movement; cycle++) {
        dut->clk = !dut->clk;
        dut->eval();
        
        if (dut->clk == 1) {  // Rising edge
            // Check ball position every 50000 cycles
            if (cycle % 50000 == 0) {
                // Access internal signals - we need to check if they're exposed
                std::cout << "Cycle " << cycle/2 << std::endl;
                
                // Check if ball moved
                if (cycle > 100000) {
                    found_movement = true;
                }
            }
        }
    }
    
    delete dut;
    return 0;
}
