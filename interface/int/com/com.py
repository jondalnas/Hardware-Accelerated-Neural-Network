"""Module to communicate over serial com port"""

# 4 commands: t, r, w, c
#  t: Test and reply, replys with 'y'
#  r: Recieve data from FPGA (group of 4 bytes minimum, to create 32 bit data,
#                             number of words specified by NN output size)
#  w: Write data to FPGA (group of 4 bytes minimum, to send 32 bit data,
#                         number of words specified by NN input size)
#  c: Clear entire memory

import serial
import random

testing = True

ser : serial.Serial = None

def open_port(port: str, baudrate: int = 9600) -> bool:
    """Open port at specific locations with certain baude rate"""
    global ser

    if testing:
        test()
        clear()
        return True

    ser = serial.Serial(port, baudrate)

    if ser is None or not test():
        return False

    clear()

    return True

def test() -> bool:
    """Test if connection to FPGA is successful"""
    if testing:
        print("Wrote: 79")
        print("Read in from COM")
        return True

    ser.write(74) # Send 't'
    return ser.read() == 79 # Expect 'y' in return

def clear():
    """Clear memory on FPGA"""
    if testing:
        print("Wrote: 63")
        return

    ser.write(63)

def send_img(img: list[list[int]], data_width: int = 2):
    """Send an image formated as an array of arrays of grayscale pixels"""
    if testing:
        print("Wrote: 77")
    else:
        ser.write(77)

    for r in img:
        for p in r:
            for i in range(data_width):
                if testing:
                    print("Wrote:", (p >> (8 * i)) & 255)
                else:
                    ser.write((p >> (8 * i)) & 255)

def recv_vector(size: int, data_width: int = 2) -> list[int]:
    """Recieve output vector from NN"""
    res = []
    for _ in range(size):
        num = 0
        for i in range(data_width):
            if testing:
                print("Read in from COM")
                num += random.randint(0, 256) << (8 * i)
            else:
                num += ser.read() << (8 * i)

        res.append(num)

    return res
