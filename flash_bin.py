from machine import Pin
import ice

print("Starting FPGA flash process...")

# Open the bitstream file
try:
    file = open("vga.bin", "rb")
    print("Bitstream file opened successfully")
except OSError:
    print("ERROR: Could not open vga.bin")
    raise

# Initialize SPI flash interface
flash = ice.flash(miso=Pin(4), mosi=Pin(7), sck=Pin(6), cs=Pin(5))

# Erase flash (optional but recommended)
print("Erasing flash...")
flash.erase(4096)

# Write bitstream to flash
print("Writing bitstream to flash...")
flash.write(file)
file.close()
print("Bitstream written successfully")

# Initialize and start FPGA with 25.175 MHz clock for VGA
print("Starting FPGA with 25.175 MHz clock...")
fpga = ice.fpga(cdone=Pin(40), clock=Pin(21), creset=Pin(31), 
                cram_cs=Pin(5), cram_mosi=Pin(4), cram_sck=Pin(6), 
                frequency=25)  # 25 MHz clock for VGA (closest to 25.175 MHz)
fpga.start()
print("FPGA started successfully!")
print("VGA display should now be showing a red screen")