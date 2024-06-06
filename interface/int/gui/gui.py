"""Module to create a simple GUI window with tkinter"""

from tkinter import Tk, Frame, Canvas, Button, Label, RIGHT, LEFT, TOP, BOTTOM
from typing import Tuple, Callable

from PIL import Image, ImageDraw

window: Tk

img = None
labels_vector: list[Label] = []

canvas_size: int = 200

def create_window(size: Tuple[int, int], upload_func: Callable, download_func: Callable):
    """Create the tkinter window"""
    global window, img

    window = Tk()
    window.geometry(f"{size[0]}x{size[1]}")

    frame = Frame(window)
    frame.pack()

    frame_top = Frame(frame)
    frame_top.pack(side=TOP)
    frame_top.grid_columnconfigure(0, weight=1)
    frame_top.grid_columnconfigure(1, weight=1)
    frame_top.grid_rowconfigure(0, weight=1)

    frame_bottom = Frame(frame)
    frame_bottom.pack(side=BOTTOM)

    frame_topleft = Frame(frame_top, bg="white")
    frame_topleft.pack(side=LEFT)

    frame_topright = Frame(frame_top)
    frame_topright.pack(side=RIGHT)

    canvas = Canvas(frame_topleft, width=canvas_size, height=canvas_size)
    canvas.pack(padx=5, pady=5)

    img = Image.new("1", (canvas_size, canvas_size), 1)
    draw = ImageDraw.Draw(img)

    def mouse_drag(event):
        #  canvas.create_line((last_x, last_y, event.x, event.y), fill='black', width=16)
        canvas.create_oval(event.x-8, event.y-8, event.x+8, event.y+8, fill="black")
        draw.ellipse((event.x-8, event.y-8, event.x+8, event.y+8), 0)

    def clear_canvas():
        canvas.delete("all")
        draw.rectangle((0, 0, canvas_size, canvas_size), 1)

    canvas.bind("<B1-Motion>", mouse_drag)

    upload_button = Button(frame_topright, text="Upload", command=upload_func)
    upload_button.pack(padx=3, pady=3)

    download_button = Button(frame_topright, text="Download", command=download_func)
    download_button.pack(padx=3, pady=3)

    clear_canvas_button = Button(frame_topright, text="Clear Canvas", command=clear_canvas)
    clear_canvas_button.pack(padx=3, pady=3)

    for i in range(10):
        f = Frame(frame_bottom)
        l = Label(f, text=f"Nr. {i}")
        l.pack(padx=3, pady=3)

        v = Label(f, text=str(0))
        v.pack(padx=3, pady=3)
        f.pack(side=LEFT)

        labels_vector.append(v)

    window.title("MNIST")
    window.mainloop()

def render(vector: list[int]):
    """Update and render data vector"""
    for (l, v) in zip(labels_vector, vector):
        l.configure(text=str(v))

def read_canvas() -> list[list[float]]:
    res = []
    for y in range(28):
        row = []
        for x in range(28):
            pixel = 0

            for yy in range((canvas_size * y) // 28, (canvas_size * (y + 1)) // 28):
                for xx in range((canvas_size * x) // 28, (canvas_size * (x + 1)) // 28):
                    if img.getpixel((xx, yy)) == 0:
                        pixel += 1

            row.append(pixel / ((canvas_size // 28) ** 2))

        res.append(row)

    return res
