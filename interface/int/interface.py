"""Connection of GUI and com port"""
import sys

from .com import send_img, recv_vector, open_port
from .gui import create_window, render, read_canvas

def run(port: str):
    """Run program, by creating window and communicating over serial"""

    if not open_port(port):
        print("Could not open com on port: ", port)
        sys.exit(0)
    create_window((640, 480), upload, download)

def upload():
    """Send image from canvas"""
    def discretize(x: float) -> int:
        return int(x * (2 ** 16 - 1))

    def dl(l: list[float]) -> list[int]:
        return list(map(discretize, l))

    send_img(map(dl, read_canvas()))

def download():
    """Function to download and render data from FPGA"""
    render(recv_vector(10))
