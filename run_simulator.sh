#!/bin/bash
# Quick start script for Pong VGA Simulator

echo "========================================="
echo "  Pong VGA Visual Simulator"
echo "========================================="
echo ""

# Check if already built
if [ ! -f "obj_dir/Vdisplay_pong" ]; then
    echo "Building simulator..."
    make sim-visual
    if [ $? -ne 0 ]; then
        echo "Build failed! Check error messages above."
        exit 1
    fi
    echo ""
fi

echo "Starting Pong simulation..."
echo "You should see:"
echo "  - Red background"
echo "  - White square ball bouncing around"
echo "  - Yellow paddle tracking the ball on the left"
echo ""
echo "Close the window or press Ctrl+C to exit"
echo ""

./obj_dir/Vdisplay_pong
