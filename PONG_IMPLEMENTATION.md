# Pong Game Implementation

## Overview
Successfully implemented a Pong demo on the ICE40UP5k FPGA with VGA output at 640x480 resolution.

## Features
- **Ball Sprite**: 16x16 pixel white square
- **Paddle Sprite**: 8x64 pixel yellow rectangle
- **Ball Physics**: 
  - Initial velocity: 100 pixels/second horizontal, 50 pixels/second vertical
  - Elastic collisions with walls and paddle
  - Fixed-point arithmetic (10.16 format) for smooth movement
- **Paddle AI**: Automatically tracks ball's vertical position
- **Background**: Red screen

## Implementation Details

### Module Structure

#### 1. `top.sv`
- Top-level module integrating all components
- Composites sprite rendering over red background
- Manages VGA output signals

#### 2. `vga_timing.sv`
- Generates VGA sync signals for 640x480 @ 60Hz
- Provides pixel coordinates and display enable signal
- Outputs frame_start pulse for game logic synchronization

#### 3. `sprite_renderer.sv`
- Renders ball and paddle sprites based on position inputs
- Ball: 16x16 white square (center-positioned)
- Paddle: 8x64 yellow rectangle (top-left positioned)
- Ball has rendering priority over paddle when overlapping

#### 4. `pong_game.sv`
- Implements game physics and collision detection
- Fixed-point arithmetic for sub-pixel accuracy
- Ball velocity: 
  - Horizontal: 1.67 pixels/frame (~100 px/s at 60Hz)
  - Vertical: 0.83 pixels/frame (~50 px/s at 60Hz)
- Paddle tracking with speed limiting (2 pixels/frame max)
- Collision detection for:
  - Top/bottom walls → vertical velocity reversal
  - Right wall → horizontal velocity reversal
  - Paddle → horizontal velocity reversal
  - Left wall (miss) → ball reset to center

### Fixed-Point Math
- Format: 26-bit signed (10 integer bits, 16 fractional bits)
- Enables smooth sub-pixel movement
- Velocity constants calculated for 60Hz frame rate

### Timing Performance
- **Target Clock**: 25 MHz (actual 25.175 MHz)
- **Achieved Frequency**: 27.82 MHz
- **Slack**: Positive (PASS)
- **Resource Usage**:
  - Logic Cells: 640/5280 (12%)
  - I/O Pins: 16/96 (16%)
  - Global Buffers: 6/8 (75%)

## Testing

### Testbenches Created
1. **sprite_renderer_tb.sv**: Tests sprite rendering logic
   - Background pixels
   - Ball sprite rendering
   - Paddle sprite rendering
   - Sprite overlap priority
   - Display enable handling

2. **pong_game_tb.sv**: Tests game physics
   - Initial positioning
   - Ball movement
   - Paddle tracking
   - Collision detection

3. **vga_tb.sv**: Tests VGA timing (pre-existing)

### Running Tests
```bash
make sim-sprite    # Test sprite rendering
make sim-pong      # Test game physics
make sim-all       # Run all tests
```

## Building and Flashing

### Build
```bash
make all
```

### Flash to FPGA
```bash
make flash
```
or
```bash
make flash-direct
```

## Files Modified/Created

### New Files
- `sprite_renderer.sv` - Sprite rendering module
- `pong_game.sv` - Game logic and physics
- `sprite_renderer_tb.sv` - Sprite renderer testbench
- `pong_game_tb.sv` - Game logic testbench
- `PONG_IMPLEMENTATION.md` - This document

### Modified Files
- `top.sv` - Updated to integrate Pong game
- `Makefile` - Added new source files and test targets

## Design Decisions

1. **Fixed-Point Arithmetic**: Chosen over integer math for smooth sub-pixel movement
2. **Center-Based Ball Positioning**: Simplifies collision detection calculations
3. **Top-Left Paddle Positioning**: Natural for left-edge placement and tracking
4. **Paddle Speed Limiting**: Prevents unrealistic instant movement
5. **Ball Reset on Miss**: Restarts game automatically when ball passes paddle
6. **Background Red**: Maintains original red screen while adding gameplay

## Future Enhancements
Possible improvements:
- Add score display
- Two-player mode with second paddle
- Adjustable difficulty
- Sound effects (if audio hardware available)
- Variable ball speed (increases over time)
- Improved collision angles based on paddle hit location
