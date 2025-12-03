#include <iostream>
#include <verilated.h>
#include "Vdisplay_pong.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdisplay_pong* dut = new Vdisplay_pong;
    
    // Reset
    dut->clk = 0;
    dut->reset_in = 1;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->reset_in = 0;
    
    // Run simulation and watch for movement
    int frame_count = 0;
    int last_ball_x = -1;
    int last_ball_y = -1;
    
    std::cout << "Starting simulation...\n";
    
    // Run for 100 frames worth of cycles
    // Each frame is 800*525 = 420000 clock cycles at 50MHz
    // = 210000 clock cycles at 25MHz (after divider)
    // But we're clocking at 50MHz, so 420000 50MHz cycles per frame
    for (int i = 0; i < 420000 * 10; i++) {
        dut->clk = 0;
        dut->eval();
        dut->clk = 1;
        dut->eval();
        
        // Check every 420000 cycles (one frame)
        if (i % 420000 == 0 && i > 0) {
            frame_count++;
            std::cout << "Frame " << frame_count << std::endl;
        }
    }
    
    std::cout << "Simulation complete after " << frame_count << " frames\n";
    
    delete dut;
    return 0;
}
