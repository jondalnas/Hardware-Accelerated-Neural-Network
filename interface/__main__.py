"""Interface with FPGA"""

import sys

from int import run

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Wrong number of values: ", len(sys.argv), "!=2", sep='')
        sys.exit(0)

    run(sys.argv[1])
