# Hardware-Accelerated-Neural-Network

A hardware accelerated implementation of ONNX in VHDL

## Hardware

The synthesis has been tested in both Vivado 2024.1 and 2023.2. Vivado 2024.1 throws errors during implementation, while Vivado 2023.2 works without any problems.

The accelerator has been tested on different FPGA boards, their status can be seen in the table below.

|FPGA       |Status   | Notes
|-----------|---------|----|
|Nexys 4 DDR|❌      |Too small|
|Basys 3    |❌      |Broken UART|


✅ means working  
❌ means not working

## How to use

To use the hardware accelerator for ONNX, first clone this repository, then follow the three steps bellow.

1. Generate VHDL for neural net ([Description](generator/README.md))
2. Synthesize neural net accelerator on FPGA ([Description](accelerator/README.md))
3. Interface over UART for uploading inputs and downloading results ([Description](interface/README.md))

A more thorough description of each can be found by following the links above.

# What Works

|Feature | Implementation status|Notes |
|--------|----------------------|------|
|Generate VHDL project from ONNX file|✅| Only using implemented operators|
|Interface with FPGA over UART|✅||
|Simulate NN|✅||
|Synthesize NN|✅||
|Implementable on Nexys 4 DDR|❌|Too many LUTs and DFFs (see [utilization](accelerator/test.md))|
|Tested on FPGA|❌|See point above|

## Future work
* Removing constants
* Smaller neural network
* Reduce to 8 bit integers
* Batch calculations to reduce number of states (LUTs)
* Implement more operators
