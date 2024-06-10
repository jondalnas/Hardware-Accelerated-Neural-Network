# Hardware-Accelerated-Neural-Network

A hardware accelerated implementation of ONNX in VHDL

## Hardware

The hardware has been tested on different FPGA boards, their status can be seen in the table below.

|FPGA       |Status   |
|-----------|---------|
|Nexys 4 DDR|✅      |
|Basys 3    |❌(Broken UART)      |


✅ means working  
❌ means not working

## How to use

To use the hardware accelerator for ONNX three steps need to be followed:

1. Generate VHDL for neural net (Description)
2. Synthezise neural net accelerator on FPGA (Description)
3. Interface over UART for uploading inputs and downloading results (Description)

A more thorough description of each can be found by following the links above.