# Pong VGA Visual Simulator

This directory contains a visual simulator for the Pong VGA demo that allows you to see the game running on your computer without needing the FPGA hardware.

## Prerequisites

The simulator uses Verilator to convert the SystemVerilog design to C++, and OpenGL/GLUT for graphics rendering.

### On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install build-essential
sudo apt-get install verilator
sudo apt-get install libglu1-mesa-dev freeglut3-dev mesa-common-dev
```

### On Fedora/RHEL:
```bash
sudo dnf install verilator
sudo dnf install freeglut-devel mesa-libGLU-devel
```

### On macOS:
```bash
brew install verilator
# OpenGL/GLUT are typically already installed on macOS
```

## Building and Running

The easiest way to build and run the simulator is using the Makefile targets:

### Build Only:
```bash
make sim-visual
```

### Build and Run:
```bash
make run-visual
```

This will:
1. Compile the SystemVerilog modules with Verilator
2. Compile the C++ simulator with OpenGL support
3. Launch a window showing the Pong game in action

## What You'll See

- A red background (640x480 resolution)
- A white 16×16 pixel square ball moving across the screen
- A yellow 8×64 pixel paddle on the left edge tracking the ball
- The ball bouncing off walls and the paddle with elastic collisions

## How It Works

The simulator:
1. **display_pong.v** - Wrapper module that interfaces the Pong design with the simulator
   - Generates a 25MHz clock from the 50MHz input
   - Instantiates the VGA timing, game logic, and sprite renderer
   - Outputs 12-bit RGB signals

2. **pong_simulator.cpp** - C++ simulator using Verilator and OpenGL
   - Runs the Verilog design cycle-by-cycle
   - Captures VGA sync signals and RGB output
   - Renders pixels to an OpenGL window in real-time

## Simulation Speed

The simulation runs at approximately real-time speed but may vary based on your computer's performance. The actual speed depends on:
- CPU performance
- Complexity of the design
- System load

## Closing the Simulator

Simply close the OpenGL window or press Ctrl+C in the terminal.

## Troubleshooting

### "verilator: command not found"
Install Verilator using the package manager commands above.

### "fatal error: GL/glut.h: No such file or directory"
Install the OpenGL/GLUT development libraries as shown in Prerequisites.

### Window appears but shows nothing or is black
The simulation may need a few moments to initialize. If it stays black, check that the design compiled without errors.

### Simulation runs very slowly
This is normal - cycle-accurate Verilog simulation can be slow. The design runs at 25MHz (25 million cycles per second), but simulation is much slower than real hardware.

## Files

- `display_pong.v` - Top-level wrapper for simulation
- `pong_simulator.cpp` - C++ OpenGL simulator
- `pong_game.sv` - Game logic (ball physics, paddle AI, collisions)
- `sprite_renderer.sv` - Sprite rendering engine
- `Makefile` - Build targets for the simulator

## Credits

The VGA simulation framework is based on [VGA-Simulation](https://github.com/SamanMohseni/VGA-Simulation) by Saman Mohseni.
