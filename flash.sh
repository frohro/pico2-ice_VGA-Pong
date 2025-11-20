#!/bin/bash

# Simplified script to flash firmware to pico2-ice (assumes firmware is pre-built)
# Usage: ./flash.sh [firmware_file]

FIRMWARE="${1:-LogicAnalyzer.uf2}"  # Default to LogicAnalyzer UF2

check_bootsel() {
    echo "Checking for device in BOOTSEL mode..."
    if picotool info -a 2>/dev/null | grep -q "RP2"; then
        echo "✓ Device found in BOOTSEL mode"
        return 0
    else
        echo "✗ No device in BOOTSEL mode found"
        return 1
    fi
}

auto_reboot_bootsel() {
    echo "Attempting to reboot device into BOOTSEL mode..."
    if ./reboot_bootsel.sh; then
        return 0
    else
        echo ""
        echo "Automatic reboot failed. Please manually enter BOOTSEL mode:"
        echo "  1. Unplug the device"
        echo "  2. Hold the BOOTSEL button"
        echo "  3. Plug in the USB cable while holding BOOTSEL"
        echo "  4. Release BOOTSEL"
        echo ""
        return 1
    fi
}

if [ ! -f "$FIRMWARE" ]; then
    echo "✗ Firmware file '$FIRMWARE' not found."
    exit 1
fi

echo "Flashing $FIRMWARE..."

# Try automatic reboot first
if ! check_bootsel; then
    auto_reboot_bootsel
fi

# Wait for mount and flash
echo "Waiting for mount at /media/$USER/RP2350..."
timeout 30 bash -c 'while [ ! -d /media/$USER/RP2350 ]; do sleep 1; done' || { echo "Mount not found within 30 seconds"; exit 1; }
echo "Flashing firmware..."
cp "$FIRMWARE" /media/$USER/RP2350/
echo "✓ Firmware flashed successfully!"
