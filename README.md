# Hardware-Accelerated-Neural-Network

A hardware accelerated implementation of ONNX in VHDL

## Hardware
The synthesis has been tested in both Vivado 2024.1 and 2023.2. Vivado 2024.1 throws errors during implementation, while Vivado 2023.2 works without any problems.

The accelerator has been tested on different FPGA boards, their status can be seen in the table below.

|FPGA       |Status   |
|-----------|---------|
|Nexys 4 DDR|✅     |
|Basys 3    |❌ (Broken UART)      |


✅ means working  
❌ means not working

## How to use

To use the hardware accelerator for ONNX three steps need to be followed:

1. Generate VHDL for neural net (Description)
2. Synthesize neural net accelerator on FPGA (Description)
3. Interface over UART for uploading inputs and downloading results (Description)

A more thorough description of each can be found by following the links above.