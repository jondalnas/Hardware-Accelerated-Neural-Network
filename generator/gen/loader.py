from __future__ import annotations
import os.path
import onnx

from enum import Enum
from dataclasses import dataclass

class MemoryInstructions(Enum):
    LoadIn = 0,
    LoadMem = 1,
    PushMem = 2,
    PushMemAndLoadIn = 3
    LoadInAndMem = 4

class Node:
    name: str
    outputs: list[Node]
    output_size: list[int]
    output_value_size: int = -1

    is_feedback: bool = False

    def __init__(self, name: str):
        self.name = name
        self.outputs = []
        self.output_size = []

    def add_input(self, name: str, n: Node):
        pass

    def replace_input(self, original: Node, new: Node):
        pass

    def calc_input_node_size(self, input_nn_size: int) -> int:
        res = 0
        for i in self.get_inputs():
            if isinstance(i, InputNode):
                res += input_nn_size
                continue

            res += i.calc_output_node_size()

        return res

    def calc_output_node_size(self) -> int:
        if self.output_value_size != -1:
            return self.output_value_size

        res = 1
        for e in self.output_size:
            res *= e

        self.output_value_size = res

        return res

    def add_output(self, output: Node):
        self.outputs.append(output)

    def get_inputs(self) -> list[Node]:
        return []

    def get_intput_broadcasts(self) -> list[tuple[int, int, int]]:
        return []

    def get_input_index(self, node: Node) -> int:
        for index, input_node in enumerate(self.get_inputs()):
            if input_node == node:
                return index

        return -1

    def calc_output_dimensions(self):
        pass

    def generate_connections(self) -> tuple[str, bool]:
        res = ""

        def rem_const(e: tuple[int, Node]):
            return not isinstance(e[1], ConstNode)

        inputs = list(filter(rem_const, enumerate(self.get_inputs())))

        def node_size(e: tuple[int, Node]):
            if isinstance(e[1], InputNode):
                return -99999

            return e[1].calc_output_node_size()

        inputs.sort(key=node_size)

        should_handshake = False

        curr_sum_size = 0
        for index, input_node in inputs[:-1]:
            curr_size = input_node.calc_output_node_size()
            res += "                " + self.name + f"_i_{index} <= input({curr_sum_size + curr_size - 1} downto {curr_sum_size});\n"
            curr_sum_size += curr_size

            should_handshake = True

        if isinstance(inputs[-1][1], InputNode):
            curr_size = inputs[-1][1].calc_output_node_size()
            res += "                " + self.name + f"_i_{len(inputs)-1} <= input({curr_sum_size + curr_size - 1} downto {curr_sum_size});\n"

            should_handshake = True
        else:
            curr_size = inputs[-1][1].calc_output_node_size()
            res += "                " + self.name + f"_i_{len(inputs)-1} <= feedback({curr_size - 1} downto 0);\n"

        if self.is_feedback:
            res += f"                next_feedback({self.calc_output_node_size() - 1} downto 0) <= " + self.name + "_o;\n"
            return (res, should_handshake)

        res += f"                output({self.calc_output_node_size() - 1} downto 0) <= " + self.name + "_o;\n"
        return (res, True)

    def calc_instruction_list_at_node(self) -> list[Node | tuple[MemoryInstructions, int]]:
        instr: list[Node | tuple[MemoryInstructions, int]] = []

        takes_nn_input: bool = False
        valid_inputs: list[Node] = []
        for i in self.get_inputs():
            if isinstance(i, InputNode):
                takes_nn_input = True
                continue

            if isinstance(i, ConstNode):
                continue

            valid_inputs.append(i)

        def size(e: Node):
            return e.calc_output_node_size()

        valid_inputs.sort(key=size)

        for i in valid_inputs:
            l = i.calc_instruction_list_at_node()
            instr.extend(l)
            instr.append((MemoryInstructions.PushMem, i.calc_output_node_size()))

        instr = instr[:-1] # Remove final store instruction
        if len(valid_inputs) > 1:
            instr.append((MemoryInstructions.LoadMem, sum(map(size, valid_inputs[:-1]))))

        if takes_nn_input:
            instr.append((MemoryInstructions.LoadIn, 0))

        if isinstance(self, OutputNode):
            instr.append((MemoryInstructions.PushMem, self.get_inputs()[0].calc_output_node_size()))
        else:
            instr.append(self)

        return instr

    def to_vhdl_entity(self, _: int) -> str:
        return "Error: Entity not implemented"

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

    is_broadcasting: bool = False

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

    def get_intput_broadcasts(self) -> list[tuple[int, int, int]]:
        if self.is_broadcasting:
            return [(1, self.b.calc_output_node_size(), self.calc_output_node_size())]
        return []

    def replace_input(self, original: Node, new: Node):
        if self.a == original:
            self.a = new
        else:
            self.b = new

    def calc_output_dimensions(self):
        if self.a.output_size == self.b.output_size:
            self.output_size = self.a.output_size

            return

        self.is_broadcasting = True

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

    def to_vhdl_entity(self, data_width: int) -> str:
        bc = "_bc" if self.is_broadcasting else ""

        return ( "    " + self.name + " : entity work.div\n"
                 "        generic map (\n"
                f"            input_size => {self.calc_output_node_size()},\n"
                f"            data_width => {data_width}\n"
                 "        )\n"
                 "        port map (\n"
                 "            a => " + self.name + "_i_0,\n"
                 "            b => " + self.name + bc + "_i_1,\n"
                 "            c => " + self.name + "_o\n"
                 "        );\n")

class ConvNode(Node):
    x: Node
    x_dimensions: list[int]
    w: Node
    w_dimensions: list[int]
    input_names: list[str]

    kernel_shape: list[int]
    dilation: list[int]
    stride: list[int]

    def __init__(self, name: str, input_names: list[str], kernel_shape: list[int], dilation: list[int], stride: list[int]):
        super().__init__(name)
        self.input_names = input_names

        self.kernel_shape = kernel_shape
        self.dilation = dilation
        self.stride = stride

    def add_input(self, name: str, n: Node):
        if name == self.input_names[0]:
            self.x = n
        elif name == self.input_names[1]:
            self.w = n

    def get_inputs(self) -> list[Node]:
        return [self.x, self.w]

    def get_intput_broadcasts(self) -> list[tuple[int, int, int]]:
        if self.kernel_shape == self.w_dimensions:
            return []

        kernel_size = 1
        for k in self.kernel_shape:
            kernel_size *= k

        return [(1, self.w.calc_output_node_size(), kernel_size)]

    def replace_input(self, original: Node, new: Node):
        if self.x == original:
            self.x = new
        else:
            self.w = new

    def calc_output_dimensions(self):
        if self.x.output_size[1] != self.w.output_size[1]:
            raise Exception("Wrong channel dimension")

        self.x_dimensions = self.x.output_size
        self.w_dimensions = self.w.output_size

        self.output_size = [1] # Probably wrong, should probably be calculated from channels of the weight and x
        self.output_size.append(self.w.output_size[0])
        self.output_size.extend(self.x.output_size[2:])

    def __str__(self):
        return "Conv"

    def to_vhdl_entity(self, data_width: int) -> str:
        num_dimensions = len(self.output_size)
        x_size = self.x.calc_output_node_size()
        w_size = self.w.calc_output_node_size()
        kernel_size = 1
        for e in self.kernel_shape:
            kernel_size *= e

        bc = "_bc" if self.kernel_shape != self.w_dimensions else ""

        return ( "    " + self.name + " : entity work.conv\n"
                 "        generic map (\n"
                f"            num_dimensions => {num_dimensions},\n"
                f"            dimensions_x => {list_to_vhdl(self.x_dimensions)},\n"
                f"            x_size => {x_size},\n"
                f"            dimensions_w => {list_to_vhdl(self.w_dimensions)},\n"
                f"            w_size => {w_size},\n"
                f"            kernel_shape => {list_to_vhdl(self.kernel_shape)},\n"
                f"            kernel_size => {kernel_size},\n"
                f"            dilation => {list_to_vhdl(self.dilation)},\n"
                f"            stride => {list_to_vhdl(self.stride)},\n"
                f"            data_width => {data_width},\n"
                f"            y_size => {self.calc_output_node_size()}\n"
                 "        )\n"
                 "        port map (\n"
                 "            x => " + self.name + "_i_0,\n"
                 "            w => " + self.name + bc + "_i_1,\n"
                 "            y => " + self.name + "_o\n"
                 "        );\n")

class AddNode(Node):
    a: Node
    b: Node
    input_names: list[str]

    broadcast_axis: int

    is_broadcasting: bool = False

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

    def get_intput_broadcasts(self) -> list[tuple[int, int, int]]:
        if self.is_broadcasting:
            return [(1, self.b.calc_output_node_size(), self.calc_output_node_size())]
        return []

    def replace_input(self, original: Node, new: Node):
        if self.a == original:
            self.a = new
        else:
            self.b = new

    def calc_output_dimensions(self):
        if self.a.output_size == self.b.output_size:
            self.output_size = self.a.output_size

            return

        self.is_broadcasting = True

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

    def to_vhdl_entity(self, data_width: int):
        bc = "_bc" if self.is_broadcasting else ""

        return ( "    " + self.name + " : entity work.add\n"
                 "        generic map (\n"
                f"            input_size => {self.calc_output_node_size()},\n"
                f"            data_width => {data_width}\n"
                 "        )\n"
                 "        port map (\n"
                 "            a => " + self.name + "_i_0,\n"
                 "            b => " + self.name + bc + "_i_1,\n"
                 "            c => " + self.name + "_o\n"
                 "        );\n")

class ReluNode(Node):
    x: Node

    def add_input(self, _: str, n: Node):
        self.x = n

    def get_inputs(self) -> list[Node]:
        return [self.x]

    def replace_input(self, _: Node, new: Node):
        self.x = new

    def calc_output_dimensions(self):
        self.output_size = self.x.output_size

    def __str__(self):
        return "Relu"

    def to_vhdl_entity(self, data_width: int) -> str:
        return ( "    " + self.name + " : entity work.relu\n"
                 "        generic map (\n"
                f"            input_size => {self.calc_output_node_size()},\n"
                f"            data_width => {data_width}\n"
                 "        )\n"
                 "        port map (\n"
                 "            x => " + self.name + "_i_0,\n"
                 "            y => " + self.name + "_o\n"
                 "        );\n")

class MaxPoolNode(Node):
    x: Node
    x_dimensions: list[int]

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

    def replace_input(self, _: Node, new: Node):
        self.x = new

    def calc_output_dimensions(self):
        self.x_dimensions = self.x.output_size
        dims = self.x.output_size[:2]

        for d,k,pb,pe,s in zip(self.x.output_size[2:], self.kernel_shape, self.pads[0:len(self.pads)//2], self.pads[len(self.pads)//2:], self.strides):
            # We shouold probably use stride for something, but I do not know what
            dims.append((d + pb + pe - k) // s + 1)

        self.output_size = dims

    def __str__(self):
        return "MaxPool"

    def to_vhdl_entity(self, data_width: int) -> str:
        num_dimensions = len(self.output_size)
        input_size = self.x.calc_output_node_size()
        output_size = self.calc_output_node_size()

        return ( "    " + self.name + " : entity work.max_pool\n"
                 "        generic map (\n"
                f"            num_dimensions => {num_dimensions},\n"
                f"            kernel_shape => {list_to_vhdl(self.kernel_shape)},\n"
                f"            pads => {list_to_vhdl(self.pads)},\n"
                f"            strides => {list_to_vhdl(self.strides)},\n"
                f"            in_dimensions => {list_to_vhdl(self.x_dimensions)},\n"
                f"            input_size => {input_size},\n"
                f"            output_size => {output_size},\n"
                f"            data_width => {data_width}\n"
                 "        )\n"
                 "        port map (\n"
                 "            x => " + self.name + "_i_0,\n"
                 "            y => " + self.name + "_o\n"
                 "        );\n")

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

    def replace_input(self, _: Node, new: Node):
        self.data = new

    def calc_output_dimensions(self):
        self.output_size = self.shape

    def __str__(self):
        return "Reshape"

class MatMulNode(Node):
    a: Node
    a_dimensions: list[int]
    b: Node
    b_dimensions: list[int]
    input_names: list[str]

    broadcasting: int = -1

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

    def get_intput_broadcasts(self) -> list[tuple[int, int, int]]:
        if self.broadcasting == 0:
            return [(0, self.a.calc_output_node_size(), self.calc_output_node_size())]

        if self.broadcasting == 1:
            return [(1, self.b.calc_output_node_size(), self.calc_output_node_size())]

        return []

    def calc_output_dimensions(self):
        self.a_dimensions = self.a.output_size
        self.b_dimensions = self.b.output_size

        if len(self.a_dimensions) == 1:
            self.a_dimensions = [1] + self.a_dimensions

        if len(self.b_dimensions) == 1:
            self.b_dimensions.append(1)

        if self.a_dimensions[-1] != self.b_dimensions[-2]:
            raise Exception("Lower dimensions of tensor incompatible")

        dims = [self.a_dimensions[-2], self.b_dimensions[-1]]

        if len(self.a_dimensions) > len(self.b_dimensions):
            for e1,e2 in zip(self.a_dimensions[len(self.a_dimensions)-len(self.b_dimensions):-2], self.b_dimensions[:-2]):
                if e1 != e2:
                    raise Exception("Upper dimensions of tensor incompatible")
            dims = self.a_dimensions[:-2] + dims
            self.broadcasting = 1
        elif len(self.a_dimensions) < len(self.b_dimensions):
            for e1,e2 in zip(self.a_dimensions[:-2], self.b_dimensions[len(self.a_dimensions)-len(self.b_dimensions):-2]):
                if e1 != e2:
                    raise Exception("Upper dimensions of tensor incompatible")
            dims = self.b_dimensions[:-2] + dims
            self.broadcasting = 0
        else:
            dims = self.a_dimensions[:-2] + dims

        self.output_size = dims

    def replace_input(self, original: Node, new: Node):
        if self.a == original:
            self.a = new
        else:
            self.b = new

    def __str__(self):
        return "MatMul"

    def to_vhdl_entity(self, data_width: int) -> str:
        num_dimensions = len(self.output_size)
        a_size = self.a.calc_output_node_size()
        b_size = self.b.calc_output_node_size()
        y_size = self.calc_output_node_size()
        bca = "_bc" if self.broadcasting == 0 else ""
        bcb = "_bc" if self.broadcasting == 1 else ""

        return ( "    " + self.name + " : entity work.mat_mul\n"
                 "        generic map (\n"
                f"            num_dimensions => {num_dimensions},\n"
                f"            a_dim => {list_to_vhdl(self.a_dimensions)},\n"
                f"            b_dim => {list_to_vhdl(self.b_dimensions)},\n"
                f"            a_size => {a_size},\n"
                f"            b_size => {b_size},\n"
                f"            y_size => {y_size},\n"
                f"            data_width => {data_width}\n"
                 "        )\n"
                 "        port map (\n"
                 "            a => " + self.name + bca + "_i_0,\n"
                 "            b => " + self.name + bcb + "_i_1,\n"
                 "            y => " + self.name + "_o\n"
                 "        );\n")

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

    def replace_input(self, _: Node, new: Node):
        self.input_node = new

    def __str__(self):
        return "Output"

@dataclass
class ModelParams:
    instructions: list[Node | tuple[MemoryInstructions, int]]
    operations: list[Node]
    mem_instructions: list[tuple[MemoryInstructions, int]]
    max_feedback: int
    max_output: int
    max_input: int
    nn_input_size: int

class Model:
    nodes: list[Node] = []

    outputs: list[Node] = []
    inputs: list[InputNode] = []
    constants: list[ConstNode] = []

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

            queue.extend(n.outputs)

    def get_max_in_out_size(self) -> tuple[int, int]:
        # TODO: Not correct! Need to take feedback into account
        max_input = 0
        max_output = 0

        inputs_size = 0
        for i in self.inputs:
            inputs_size += i.calc_output_node_size()

        for n in self.nodes:
            in_node_size = n.calc_input_node_size(inputs_size)
            out_node_size = n.calc_output_node_size()

            if max_input < in_node_size:
                max_input = in_node_size

            if max_output < out_node_size:
                max_output = out_node_size

        return (max_input, max_output)

    def optimize_tree(self) -> None:
        # TODO: Also optimize operators only taking constant inputs

        for n in self.nodes:
            if isinstance(n, ReshapeNode):
                p = n.get_inputs()[0]
                p.outputs.remove(n)
                p.outputs.extend(n.outputs)

                for c in n.outputs:
                    c.replace_input(n, p)

                del n

    def generate_signals(self) -> list[tuple[str, int]]:
        res = []

        for n in self.nodes:
            if isinstance(n, (ConstNode, InputNode, ReshapeNode)):
                continue

            if len(n.outputs) != 0:
                res.append((n.name + "_o", n.calc_output_node_size()))

            for i,input_node in enumerate(n.get_inputs()):
                res.append((n.name + f"_i_{i}", input_node.calc_output_node_size()))
                
            for index, _, size in n.get_intput_broadcasts():
                res.append((n.name + f"_bc_i_{index}", size))

        return res

    def calc_model_params(self) -> ModelParams:
        res = []

        input_nn_size = 0

        for i in self.inputs:
            input_nn_size += i.calc_output_node_size()

        max_feedback = 0
        max_output = 0
        max_input = input_nn_size

        operators = []
        mem_instr = []

        for o in self.outputs:
            max_output = max(o.calc_input_node_size(input_nn_size), max_output)

        for o in self.outputs:
            instr = o.calc_instruction_list_at_node()

            skip_next: bool = False
            new_instr: list[Node | tuple[MemoryInstructions, int]] = []
            for e, en in zip(instr, instr[1:]):
                if skip_next:
                    skip_next = False
                    continue

                if isinstance(e, tuple):
                    mem_instr.append(e)

                    if isinstance(en, tuple):
                        if e[0] == MemoryInstructions.PushMem and en[0] == MemoryInstructions.LoadIn:
                            # Is push + Load In
                            new_instr.append((MemoryInstructions.PushMemAndLoadIn, e[1]))
                            skip_next = True
                            continue

                        if e[0] == MemoryInstructions.LoadMem and en[0] == MemoryInstructions.LoadIn:
                            # Is load memory + in
                            new_instr.append((MemoryInstructions.LoadInAndMem, e[1]))
                            skip_next = True

                            max_input = max(e[1] + input_nn_size, max_input)
                            continue

                    elif e[0] == MemoryInstructions.LoadMem:
                        # Is loading only from memory
                        max_input = max(e[1], max_input)

                    if e[0] == MemoryInstructions.PushMem:
                        max_output = max(e[1], max_output)

                else:
                    operators.append(e)

                    if isinstance(en, Node) or en[0] != MemoryInstructions.PushMem:
                        e.is_feedback = True
                        max_feedback = max(e.calc_output_node_size(), max_feedback)

                new_instr.append(e)

            new_instr.append(instr[-1])

            res.extend(new_instr)

        if isinstance(instr[-1], tuple):
            mem_instr.append(instr[-1])

        return ModelParams(res, operators, mem_instr, max_feedback, max_output, max_input, input_nn_size)

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
            return ConvNode(n.name, n.input, list(find_attribute(n.attribute, "kernel_shape").ints), list(find_attribute(n.attribute, "dilations").ints), list(find_attribute(n.attribute, "strides").ints))

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

def list_to_vhdl(l: list[int]) -> str:
    res = "("

    for e in l:
        res += str(e)
        res += ", "

    return res[:-2] + ")"
