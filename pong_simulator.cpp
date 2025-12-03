// Pong Game VGA Simulator using Verilator and OpenGL
// Based on VGA-Simulation by Saman Mohseni

#include <verilated.h>
#include <GL/glut.h>
#include <thread>
#include <iostream>

#include "Vdisplay_pong.h"   // from Verilating "display_pong.v"

using namespace std;

Vdisplay_pong* display;      // instantiation of the model

uint64_t main_time = 0;      // current simulation time
double sc_time_stamp() {     // called by $time in Verilog
    return main_time;
}

// to wait for the graphics thread to complete initialization
bool gl_setup_complete = false;

// 640X480 VGA sync parameters
const int LEFT_PORCH        =   48;
const int ACTIVE_WIDTH      =   640;
const int RIGHT_PORCH       =   16;
const int HORIZONTAL_SYNC   =   96;
const int TOTAL_WIDTH       =   800;

const int TOP_PORCH         =   33;
const int ACTIVE_HEIGHT     =   480;
const int BOTTOM_PORCH      =   10;
const int VERTICAL_SYNC     =   2;
const int TOTAL_HEIGHT      =   525;

// pixels are buffered here
float graphics_buffer[ACTIVE_WIDTH][ACTIVE_HEIGHT][3] = {};

// calculating each pixel's size in accordance to OpenGL system
// each axis in OpenGL is in the range [-1:1]
float pixel_w = 2.0 / ACTIVE_WIDTH;
float pixel_h = 2.0 / ACTIVE_HEIGHT;

// gets called periodically to update screen
void render(void) {
    glClear(GL_COLOR_BUFFER_BIT);
    
    // convert pixels into OpenGL rectangles
    for(int i = 0; i < ACTIVE_WIDTH; i++){
        for(int j = 0; j < ACTIVE_HEIGHT; j++){
            glColor3f(graphics_buffer[i][j][0], graphics_buffer[i][j][1], graphics_buffer[i][j][2]);
            glRectf(i*pixel_w-1, -j*pixel_h+1, (i+1)*pixel_w-1, -(j+1)*pixel_h+1);
        }
    }
    
    glutSwapBuffers();
}

void idle(void) {
    render();
}

// initializes OpenGL properties
void init() {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    gl_setup_complete = true;
}

// thread for running the graphics
void graphics_thread(int argc, char *argv[]) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE);
    glutInitWindowSize(ACTIVE_WIDTH, ACTIVE_HEIGHT);
    glutInitWindowPosition(100, 100);
    glutCreateWindow("Pong Game VGA Simulation");
    init();
    glutDisplayFunc(render);
    glutIdleFunc(idle);
    glutMainLoop();
}

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);
    display = new Vdisplay_pong;     // Create instance

    // start the graphics thread
    thread th(graphics_thread, argc, argv);
    
    // wait for graphics thread to setup
    while(!gl_setup_complete) {}
    
    cout << "Pong Game VGA Simulation Started!" << endl;
    cout << "OpenGL window should appear..." << endl;
    cout << "Watch the ball bounce around the screen!" << endl;
    cout << "" << endl;
    cout << "NOTE: Simulation runs with 8x cycle skipping for speed!" << endl;
    cout << "      Skipping 7 out of 8 cycles to make it run faster." << endl;
    cout << "" << endl;
    cout << "Close the window to exit." << endl;
    
    // reset
    display->reset_in = 1;
    display->clk = 0;
    
    // run reset for a few cycles
    for(int i = 0; i < 10; i++) {
        display->clk = 0;
        display->eval();
        main_time++;
        display->clk = 1;
        display->eval();
        main_time++;
    }
    
    // release reset
    display->reset_in = 0;
    
    // simulation variables
    int h_count = 0;
    int v_count = 0;
    bool prev_clk_25 = false;
    
    // Cycle skip counter for faster simulation
    const int CYCLE_SKIP = 8;  // Process 1 out of every 8 cycles
    int skip_counter = 0;
    
    // Run simulation
    while (!Verilated::gotFinish()) {
        // Skip cycles for faster simulation
        skip_counter++;
        if (skip_counter < CYCLE_SKIP) {
            continue;
        }
        skip_counter = 0;
        
        // Toggle 50MHz clock
        display->clk = 0;
        display->eval();
        main_time++;
        
        display->clk = 1;
        display->eval();
        main_time++;
        
        // Detect rising edge of 25MHz clock (after divider)
        // Track VGA position by counting pixels
        // We need to track the internal clk_div to know when we advance
        // Since we can't access internal signals easily, we track every other 50MHz cycle
        
        // Read VGA signals on 50MHz clock
        bool h_sync = display->h_sync;
        bool v_sync = display->v_sync;
        unsigned int rgb = display->rgb;
        
        // Extract RGB components (4 bits each)
        unsigned int r = (rgb >> 8) & 0xF;
        unsigned int g = (rgb >> 4) & 0xF;
        unsigned int b = rgb & 0xF;
        
        // Convert 4-bit to float [0.0, 1.0]
        float r_float = r / 15.0f;
        float g_float = g / 15.0f;
        float b_float = b / 15.0f;
        
        // Track 25MHz rising edges (every other 50MHz cycle)
        // The clock divider toggles, so we get 25MHz edge every 2 cycles
        static int clk_25_counter = 0;
        clk_25_counter++;
        
        if (clk_25_counter >= 2) {
            clk_25_counter = 0;
            
            // Advance pixel position
            h_count++;
            if (h_count >= TOTAL_WIDTH) {
                h_count = 0;
                v_count++;
                if (v_count >= TOTAL_HEIGHT) {
                    v_count = 0;
                }
            }
            
            // Check if we're in active area
            bool active_area = (h_count < ACTIVE_WIDTH) && (v_count < ACTIVE_HEIGHT);
            
            // Store pixel data if in active area
            if (active_area) {
                graphics_buffer[h_count][v_count][0] = r_float;
                graphics_buffer[h_count][v_count][1] = g_float;
                graphics_buffer[h_count][v_count][2] = b_float;
            }
        }
        
        // Print progress every 10 million cycles (less verbose)
        if (main_time % 10000000 == 0 && main_time > 0) {
            cout << "Simulation time: " << main_time << " cycles" << endl;
        }
        
        // Print initial positions after reset
        static bool printed_initial = false;
        if (!printed_initial && main_time > 1000) {
            printed_initial = true;
            cout << "\nDEBUG: Checking internal state..." << endl;
            cout << "Note: Internal signals not directly accessible in Verilator" << endl;
            cout << "Observing RGB output to detect sprites..." << endl;
        }
    }
    
    display->final();
    delete display;
    th.join();
    
    return 0;
}
