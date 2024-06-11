# Interface
The main purpos of the interface is to upload the initial input data onto the FPGA's RAM, and download the output from the FPGA. To achieve this, a UART communication to the FPGA is created, where the FPGA will send/recieve this data.

# How To Use
To run the program, execute the main python file with the port of the FPGA as its argument, e.g. if the FPGA is connected to /dev/ttyUSB1, the command would be:

```python . /dev/ttyUSB1```

# Technical Details
The program consits of two main parts, the GUI, to visualize the data, and the communication, to send the data.

## GUI
The GUI is created in tkinter, allowing easy design, and possibly redesign if some other model is wished to be synthesized.

First a call to ```create_window``` is made, that initializes the drawing area, the buttons to upload, download, and clear the screen, and the 10 output labels. The call also has two functions as its arguments, for the upload and download buttons.

Once the upload button is pressed, a call to ```read_canvas``` is made to convert the 200x200 pixel 1-bit depth screen to a 28x28 16-bit depth screen, by summing pixels in a 7x7 patch. This is then sent to the FPGA via the communication functions.

Pressing the download button results in the data being copied over from the FPGA to the program, and then a call to ```render``` is made, with the data list as an argument, this then updates and displays the new values.

## Communication
Communication with the FPGA happens over UART, with the python Serial library to establish it. To do this, a call to ```open_port``` is made, which first establishes the connection, with a given baude rate to a given port, then the ```test``` function is called, which sends a 't' to the FPGA, and expects a 'y' in return, this makes sure that it is our hardware we are connected to. Lastly the FPGA memory is cleared with the ```clear``` function, which sends a 'c' to the FPGA. After this point, the communication to the FPGA is established and data can now be moved.

To send the image to the FPGA, a call to ```send_img``` is made, which first sends a 'w', indicating that we want to send the input data, then it goes through each pixel of the image, and sends it to the FPGA 2 byte values, capped at $2^16-1$.

To recieve the data from the FPGA, a call to ```recv_vector``` is made, which first sends an 'r', indicating that we expect the FPGA to send its data to us, then we append each 2 byte par to an array, and convert it to an integer.


