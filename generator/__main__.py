"""Python script to generate the neural network VHDL file"""

import sys
import os.path
import pathlib

from gen import Model
from gen import convert_model

def ask_confirmation(msg: str, default_yes: bool) -> bool:
    while True:
        confirmation = input(msg + " [Y/n] " if default_yes else msg + " [y/N] ")
        if confirmation == "y":
            return True

        if confirmation == "n":
            return False

        if len(confirmation) == 0:
            return default_yes

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Wrong number of values: ", len(sys.argv), " != 4", sep='')
        sys.exit(0)

    model_path = pathlib.Path(os.path.expanduser(sys.argv[1])).resolve()
    nn_vhdl_path = pathlib.Path(os.path.expanduser(sys.argv[2])).resolve()
    defs_vhdl_path = pathlib.Path(os.path.expanduser(sys.argv[3])).resolve()

    if nn_vhdl_path.is_file() and not ask_confirmation("File " + str(nn_vhdl_path) + " already exists, overwrite it?", False):
        sys.exit(0)

    if defs_vhdl_path.is_file() and not ask_confirmation("File " + str(defs_vhdl_path) + " already exists, overwrite it?", False):
        sys.exit(0)

    m = Model(model_path)

    m.calc_dimensions()

    #  print(m)
    #  print()
    #  print("Max input and output:", m.get_max_in_out_size())
    #  print()
    m.optimize_tree()
    #  print(m)
    #  print()
    #  print("List of all signals:", m.generate_signals())
    #  print()
    nn, defs = convert_model(m)

    with open(nn_vhdl_path, 'w', encoding="utf-8") as f:
        f.write(nn)

    with open(defs_vhdl_path, 'w', encoding="utf-8") as f:
        f.write(defs)
