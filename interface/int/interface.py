"""Connection of GUI and com port"""
import sys

from .com import send_img, recv_vector, open_port
from .gui import create_window, render

def run(port: str):
    """Run program, by creating window and communicating over serial"""

    if not open_port(port):
        print("Could not open com on port: ", port)
        sys.exit(0)
    create_window((640, 480), upload, download)

def upload():
    """Send image from canvas"""
    send_img([[0, 1], [2, 3]])

def download():
    """Function to download and render data from FPGA"""
    render(recv_vector(10))
