"""Python script to generate the neural network VHDL file"""

import sys
import os.path
import onnx

from gen import Model

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Wrong number of values: ", len(sys.argv), "!=2", sep='')
        sys.exit(0)

    model_path = os.path.expanduser(sys.argv[1])
    m = Model(model_path)

    m.calc_dimensions()

    print(m)
    print()
    print("Max input and output:", m.get_max_in_out_size())
    print()
    m.optimize_tree()
    print(m)
