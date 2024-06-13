from __future__ import annotations
import os.path
import onnx

class Node:
    name: str
    outputs: list[Node]
    output_size: list[int]

    def __init__(self, name: str):
        self.name = name
        self.outputs = []
        self.output_size = []

    def add_input(self, name: str, n: Node):
        pass

    def add_output(self, output: Node):
        self.outputs.append(output)

    def get_inputs(self) -> list[Node]:
        return []

    def calc_output_dimensions(self):
        pass

class ConstNode(Node):
    c: list[int]

    def __init__(self, name: str, c: list[int], output_size: list[int]):
        super().__init__(name)

        self.c = c

        if output_size:
            self.output_size = output_size

        else:
            self.output_size = [1]

    def __str__(self):
        return "Const"

class DivNode(Node):
    a: Node
    b: Node
    input_names: list[str]

    broadcast_axis: int

    def __init__(self, name: str, input_names: list[str], broadcast_axis: int):
        super().__init__(name)
        self.input_names = input_names
        self.broadcast_axis = broadcast_axis

    def add_input(self, name: str, n: Node):
        if name == self.input_names[0]:
            self.a = n
        elif name == self.input_names[1]:
            self.b = n

    def get_inputs(self) -> list[Node]:
        return [self.a, self.b]

    def calc_output_dimensions(self):
        if self.a.output_size == self.b.output_size:
            self.output_size = self.a.output_size

            return

        # B is only allowed to be broadcast to A, not the other way around
        # Check if B is a scalar tensor
        b_scalar_tensor = True
        for e in self.b.output_size:
            if e != 1:
                b_scalar_tensor = False

        if b_scalar_tensor:
            self.output_size = self.a.output_size

            return

        # Check if A and B match from broadcast_axis in A until there is no more elements in B
        # Add dimensions of A until broadcast_axis, then add the matching axis, and finaly append the remaining dimensions of A
        for ai,bi in zip(self.a.output_size[self.broadcast_axis:], self.b.output_size):
            if ai != bi:
                raise Exception("Wrong dimensions")

        self.output_size = self.a.output_size

    def __str__(self):
        return "Div"

class ConvNode(Node):
    x: Node
    w: Node
    input_names: list[str]

    kernel_shape: list[int]

    def __init__(self, name: str, input_names: list[str], kernel_shape: list[int]):
        super().__init__(name)
        self.input_names = input_names

        self.kernel_shape = kernel_shape

    def add_input(self, name: str, n: Node):
        if name == self.input_names[0]:
            self.x = n
        elif name == self.input_names[1]:
            self.w = n

    def get_inputs(self) -> list[Node]:
        return [self.x, self.w]

    def calc_output_dimensions(self):
        if self.x.output_size[1] != self.w.output_size[1]:
            raise Exception("Wrong channel dimension")

        self.output_size = [1] # Probably wrong, should probably be calculated from channels of the weight and x
        self.output_size.append(self.w.output_size[0])
        self.output_size.extend(self.x.output_size[2:])

    def __str__(self):
        return "Conv"

class AddNode(Node):
    a: Node
    b: Node
    input_names: list[str]

    broadcast_axis: int

    def __init__(self, name: str, input_names: list[str], broadcast_axis: int):
        super().__init__(name)
        self.input_names = input_names
        self.broadcast_axis = broadcast_axis

    def add_input(self, name: str, n: Node):
        if name == self.input_names[0]:
            self.a = n
        elif name == self.input_names[1]:
            self.b = n

    def get_inputs(self) -> list[Node]:
        return [self.a, self.b]

    def calc_output_dimensions(self):
        if self.a.output_size == self.b.output_size:
            self.output_size = self.a.output_size

            return

        # B is only allowed to be broadcast to A, not the other way around
        # Check if B is a scalar tensor
        b_scalar_tensor = True
        for e in self.b.output_size:
            if e != 1:
                b_scalar_tensor = False

        if b_scalar_tensor:
            self.output_size = self.a.output_size

            return

        # Check if A and B match from broadcast_axis in A until there is no more elements in B
        # Add dimensions of A until broadcast_axis, then add the matching axis, and finaly append the remaining dimensions of A
        for ai,bi in zip(self.a.output_size[self.broadcast_axis:], self.b.output_size):
            if ai != bi:
                raise Exception("Wrong dimensions")

        self.output_size = self.a.output_size

    def __str__(self):
        return "Add"

class ReluNode(Node):
    x: Node

    def add_input(self, _: str, n: Node):
        self.x = n

    def get_inputs(self) -> list[Node]:
        return [self.x]

    def calc_output_dimensions(self):
        self.output_size = self.x.output_size

    def __str__(self):
        return "Relu"

class MaxPoolNode(Node):
    x: Node

    kernel_shape: list[int]
    pads: list[int]
    strides: list[int]

    def __init__(self, name: str, kernel_shape: list[int], pads: list[int], strides: list[int]):
        super().__init__(name)

        self.kernel_shape = kernel_shape
        self.pads = pads
        self.strides = strides

    def add_input(self, _: str, n: Node):
        self.x = n

    def get_inputs(self):
        return [self.x]

    def calc_output_dimensions(self):
        dims = self.x.output_size[:2]

        for d,k,pb,pe,s in zip(self.x.output_size[2:], self.kernel_shape, self.pads[0:len(self.pads)//2], self.pads[len(self.pads)//2:], self.strides):
            # We shouold probably use stride for something, but I do not know what
            dims.append((d + pb + pe - k) // s + 1)

        self.output_size = dims

    def __str__(self):
        return "MaxPool"

class ReshapeNode(Node):
    data: Node
    shape: list[int]

    def __init__(self, name: str, shape: list[int]):
        super().__init__(name)

        self.shape = shape

    def add_input(self, _: str, n: Node):
        self.data = n

    def get_inputs(self) -> list[Node]:
        return [self.data]

    def calc_output_dimensions(self):
        self.output_size = self.shape

    def __str__(self):
        return "Reshape"

class MatMulNode(Node):
    a: Node
    b: Node
    input_names: list[str]

    def __init__(self, name: str, input_names: list[str]):
        super().__init__(name)

        self.input_names = input_names

    def add_input(self, name: str, n: Node):
        if name == self.input_names[0]:
            self.a = n
        elif name == self.input_names[1]:
            self.b = n

    def get_inputs(self):
        return [self.a, self.b]

    def calc_output_dimensions(self):
        if self.a.output_size[-1] != self.b.output_size[-2]:
            raise Exception("Lower dimensions of tensor incompatible")

        dims = [self.a.output_size[-2], self.b.output_size[-1]]

        if len(self.a.output_size) > len(self.b.output_size):
            for e1,e2 in zip(self.a.output_size[len(self.a.output_size)-len(self.b.output_size):-2], self.b.output_size[:-2]):
                if e1 != e2:
                    raise Exception("Upper dimensions of tensor incompatible")
            dims = self.a.output_size[:-2] + dims
        elif len(self.a.output_size) < len(self.b.output_size):
            for e1,e2 in zip(self.a.output_size[:-2], self.b.output_size[len(self.a.output_size)-len(self.b.output_size):-2]):
                if e1 != e2:
                    raise Exception("Upper dimensions of tensor incompatible")
            dims = self.b.output_size[:-2] + dims

        self.output_size = dims

    def __str__(self):
        return "MathMul"

class InputNode(Node):
    def __init__(self, name: str, dimensions: list[int]):
        super().__init__(name)

        self.output_size = dimensions

    def __str__(self):
        return "Input"

class OutputNode(Node):
    input_node: Node

    def add_input(self, _: str, n: Node):
        self.input_node = n

    def get_inputs(self) -> list[Node]:
        return [self.input_node]

    def __str__(self):
        return "Output"

class Model:
    nodes: list[Node] = []

    outputs: list[Node] = []
    inputs: list[Node] = []
    constants: list[Node] = []

    input_attribs: dict[str, list[int]] = {}
    output_attribs: dict[str, list[int]] = {}

    def __init__(self, path: str):
        model_path = os.path.expanduser(path)
        onnx_model = onnx.load(model_path)

        self.input_attribs = get_input_attribs(onnx_model.graph)
        self.output_attribs = get_output_attribs(onnx_model.graph)

        ins: dict[str, list[Node]] = {}
        outs: dict[str, Node] = {}

        for n in onnx_model.graph.node:
            node = convert_op_type(n)

            if isinstance(node, ConstNode):
                self.constants.append(node)

            self.nodes.append(node)

            for inputs in n.input:
                if inputs in self.input_attribs:
                    in_node = InputNode(inputs, self.input_attribs[inputs])

                    in_node.add_output(node)
                    node.add_input(inputs, in_node)

                    self.inputs.append(in_node)

                    continue

                if not inputs in ins:
                    ins[inputs] = []

                ins[inputs].append(node)

                if inputs in outs:
                    # Some node has this input as its output
                    outs[inputs].add_output(node)
                    node.add_input(inputs, outs[inputs])

            for outputs in n.output:
                if outputs in self.output_attribs:
                    out_node = OutputNode(outputs)

                    out_node.add_input(outputs, node)
                    node.add_output(out_node)

                    self.outputs.append(out_node)

                    continue

                # If outputs is already in outs, then something is wronog
                outs[outputs] = node

                if outputs in ins:
                    # Some node has this output as its input
                    for i in ins[outputs]:
                        i.add_input(outputs, node)
                        node.add_output(i)

    def calc_dimensions(self) -> None:
        queue: list[Node] = []

        for i in self.inputs:
            queue.extend(i.outputs)

        for c in self.constants:
            queue.extend(c.outputs)

        while queue:
            n = queue.pop(0)

            # Check if output size has already been calculated
            if n.output_size:
                continue

            # Check if all inputs has calculated their outputs
            if not has_all_output_sizes(n):
                continue

            n.calc_output_dimensions()

            print(n, n.output_size)

            queue.extend(n.outputs)

    def __repr__(self) -> str:
        res = ""
        tree_str = ""

        l: list = self.outputs.copy()

        ittr = 0

        while l:
            n = l.pop()

            if isinstance(n, tuple):
                res += tree_str + "\n\n"
                tree_str = "v" + str(n[1].output_size) + "\n" + str(n[0])
                n = n[1]

            if len(n.get_inputs()) == 0:
                tree_str = str(n) + "\n" + tree_str
                continue

            if len(n.get_inputs()) == 1:
                l.append(n.get_inputs()[0])
                tree_str = "v" + str(n.get_inputs()[0].output_size) + "\n" + str(n) + "\n" + tree_str
                continue

            tree_str = "v" + str(n.get_inputs()[0].output_size) + "\n" + str(n) + " < " + str(ittr) + "\n" + tree_str

            l.extend(list(map(lambda e: (ittr, e), n.get_inputs()[1:])))
            l.append(n.get_inputs()[0])

            ittr += 1

        res += tree_str + "\n\n"

        return res

def convert_op_type(n: onnx.NodeProto) -> Node:
    """Convert op type string to node"""
    match n.op_type:
        case "Add":
            return AddNode(n.name, n.input, int(find_attribute(n.attribute, "broadcast").i))

        case "Div":
            return DivNode(n.name, n.input, int(find_attribute(n.attribute, "broadcast").i))

        case "Conv":
            return ConvNode(n.name, n.input, list(find_attribute(n.attribute, "kernel_shape").ints))

        case "Relu":
            return ReluNode(n.name)

        case "MaxPool":
            return MaxPoolNode(n.name, list(find_attribute(n.attribute, "kernel_shape").ints), list(find_attribute(n.attribute, "pads").ints), list(find_attribute(n.attribute, "strides").ints))

        case "Reshape":
            return ReshapeNode(n.name, find_attribute(n.attribute, "shape").ints)

        case "Constant":
            v = find_attribute(n.attribute, "value")
            return ConstNode(n.name, v.t.float_data, v.t.dims)

        case "MatMul":
            return MatMulNode(n.name, n.input)

    raise Exception(n.op_type + " operation not defined")


def find_attribute(attrib: list[onnx.AttributeProto], s: str) -> onnx.AttributeProto:
    for a in attrib:
        if a.name == s:
            return a

    raise Exception(s + " not an attribute")

def get_input_attribs(graph: onnx.GraphProto) -> dict[str, list[int]]:
    res = {}

    for i in graph.input:
        dims = []

        for d in i.type.tensor_type.shape.dim:
            dims.append(d.dim_value)

        res[i.name] = dims

    return res

def get_output_attribs(graph: onnx.GraphProto) -> dict[str, list[int]]:
    res = {}

    for o in graph.output:
        dims = []

        for d in o.type.tensor_type.shape.dim:
            dims.append(d.dim_value)

        res[o.name] = dims

    return res

def has_all_output_sizes(node: Node):
    for o in node.get_inputs():
        if not o.output_size:
            return False

    return True
