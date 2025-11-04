#!/usr/bin/env python3
"""
Convert binary hex file to program.mem format for Verilog $readmemh.
Usage: python hex2mem.py input.hex output.mem
"""
import sys

def hex2mem(input_file, output_file):
    with open(input_file, 'rb') as f:
        data = f.read()
    
    with open(output_file, 'w') as f:
        # Process 4 bytes at a time (32-bit words)
        for i in range(0, len(data), 4):
            word = data[i:i+4]
            # Pad if less than 4 bytes
            if len(word) < 4:
                word = word + b'\x00' * (4 - len(word))
            # Convert to hex string with spaces between bytes (little-endian format)
            hex_str = ' '.join(f'{b:02x}' for b in word)
            f.write(hex_str + '\n')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input.hex output.mem")
        sys.exit(1)
    
    hex2mem(sys.argv[1], sys.argv[2])
    print(f"Converted {sys.argv[1]} to {sys.argv[2]}")
