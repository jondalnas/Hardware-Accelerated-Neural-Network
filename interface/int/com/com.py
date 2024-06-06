# 4 commands: t, r, w, c
#  t: Test and reply, replys with 'y'
#  r: Recieve data from FPGA (group of 4 bytes minimum, to create 32 bit data, number of words specified by NN output size)
#  w: Write data to FPGA (group of 4 bytes minimum, to send 32 bit data, number of words specified by NN input size)
#  c: Clear entire memory

import serial

ser : serial.Serial = None

def open(port: str, baudrate: int = 9600) -> bool:
    ser = serial.Serial(port, baudrate)

    if not test():
        return False

    clear()

    return True

def test() -> bool:
    ser.write(74) # Send 't'
    return ser.read() == 79 # Expect 'y' in return

def clear():
    ser.write(63)

def send_img(img: list[list[int]], data_width: int = 2):
    ser.write(77)

    for r in img:
        for p in r:
            for i in range(data_width):
                ser.write((p >> (8 * i)) & 255)

def recv_vector(size: int, data_width: int = 2) -> list[int]:
    res = []
    for _ in range(size):
        num = 0
        for i in range(data_width):
            num += ser.read() << (8 * i)

        res.append(num)

    return res
