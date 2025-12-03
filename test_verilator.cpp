// Simple C++ test to check if Verilator model works correctly
#include <iostream>
#include <verilated.h>
#include "Vdisplay_pong.h"

int main() {
    Vdisplay_pong* dut = new Vdisplay_pong;
    
    std::cout << "=== Verilator Pong Test ===\n\n";
    
    // Reset
    dut->clk = 0;
    dut->reset_in = 1;
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
    }
    dut->reset_in = 0;
    
    // Run a few clock cycles after reset
    for (int i = 0; i < 10; i++) {
        dut->clk = !dut->clk;
        dut->eval();
    }
    
    std::cout << "After reset:\n";
    std::cout << "  RGB output: 0x" << std::hex << (int)dut->rgb << std::dec << "\n";
    
    // Run for several frames and track ball position
    // Each frame is 800*525 = 420000 50MHz cycles
    int frame_count = 0;
    bool frame_start_seen = false;
    
    for (int cycle = 0; cycle < 420000 * 10 && frame_count < 5; cycle++) {
        dut->clk = 0;
        dut->eval();
        dut->clk = 1;
        dut->eval();
        
        // Check for new frame (at start of visible area)
        if ((cycle % 420000) == 0 && cycle > 0) {
            frame_count++;
            std::cout << "\nFrame " << frame_count << " (cycle " << cycle << "):\n";
            std::cout << "  RGB: 0x" << std::hex << (int)dut->rgb << std::dec << "\n";
        }
    }
    
    std::cout << "\n=== Test Complete ===\n";
    std::cout << "Frames processed: " << frame_count << "\n";
    
    delete dut;
    return 0;
}
