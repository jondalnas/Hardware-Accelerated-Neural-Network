"""Module to create a simple GUI window with tkinter"""

from tkinter import Tk, Frame, Canvas, Button, Label, RIGHT, LEFT, TOP, BOTTOM
from typing import Tuple

window: Tk

drawing_canvas: Canvas
labels_vector: list[Label] = []

def create_window(size: Tuple[int, int]):
    """Create the tkinter window"""
    global window

    window = Tk()
    window.geometry(f"{size[0]}x{size[1]}")

    frame = Frame(window)
    frame.pack()

    frame_top = Frame(frame)
    frame_top.pack(side=TOP)

    frame_bottom = Frame(frame)
    frame_bottom.pack(side=BOTTOM)

    frame_topleft = Frame(frame_top)
    frame_topleft.pack(side=LEFT)

    frame_topright = Frame(frame_top)
    frame_topright.pack(side=RIGHT)

    canvas_topleft = Canvas(frame_topleft)
    canvas_topleft.pack(padx=5, pady=5)

    upload_button = Button(frame_topright, text="Upload")
    upload_button.pack(padx=3, pady=3)

    download_button = Button(frame_topright, text="Download")
    download_button.pack(padx=3, pady=3)

    for i in range(10):
        f = Frame(frame_bottom)
        l = Label(f, text=f"Number {i}")
        l.pack(padx=3, pady=3)

        v = Label(f, text=str(0))
        v.pack(padx=3, pady=3)
        f.pack()

    window.title("MNIST")
    window.mainloop()

def render(vector: list[int]):
    """Update and render data vector"""
    for (l, v) in zip(labels_vector, vector):
        l.configure(text=str(v))
