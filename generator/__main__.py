import sys
import os.path
import onnx

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Wrong number of values: ", len(sys.argv), "!=2", sep='')
        exit(0)

    model_path = os.path.expanduser(sys.argv[1])
    onnx_model = onnx.load(model_path)

    print(onnx_model)
