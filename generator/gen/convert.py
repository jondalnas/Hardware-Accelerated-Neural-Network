"""Convert onnyx model tree into VHDL file"""

from math import log2

from .loader import Model, ModelParams

def convert_model(model: Model) -> str:
    res = ""

    params = model.calc_model_params()

    with open("template.vhd", 'r', encoding="utf-8") as f:
        for l in f:
            if l.startswith("-- STATES"):
                res += get_states(params)
            elif l.startswith("-- SIGNALS"):
                res += get_signals(model)
            elif l.startswith("-- FSM"):
                res += get_fsm(params)
            elif l.startswith("-- ENTITIES"):
                res += get_entities(model)
            elif l.startswith("-- CONSTANT"):
                res += get_constant(model)
            else:
                res += l

    return res

def get_states(params: ModelParams) -> str:
    return f"    constant num_states : positive := {len(params.operations)};\n    signal state, next_state : std_logic_vector({int(log2(len(params.operations) + 1) - 1)} downto 0);\n"

def get_signals(model: Model) -> str:
    res = ""
    START = "    signals "

    for sn,sw in model.generate_signals():
        res += START + sn + f" : array_type({sw} downto 0)(data_width-1 downto 0);\n"

    return res

def get_fsm(params: ModelParams) -> str:
    res = ""

    for i, n in enumerate(params.operations):
        connection, should_handshake = n.generate_connections()

        res += f"            when {i+1}:\n"
        res += connection
        if not should_handshake or i == 0:
            res += "                next_state <= state + 1;\n"
        else:
            res += "                if valid_in then\n"
            res += "                    valid_out <= '0';\n"
            res += "                    was_valid <= '1';\n"
            res += "                elsif was_valid then\n"
            res += "                    was_valid <= '0'\n"
            if i == len(params.operations):
                res += "                    next_state <= state + 1;\n"
            else:
                res += "                    next_state <= 0;\n"
            res += "                end if;\n"

    return res

def get_entities(model: Model) -> str:
    res = ""

    for n in model.nodes:
        res += ""# n.to_vhdl_entity()

    return res

def get_constant(model: Model) -> str:
    res = ""

    for c in model.constants:
        for o in c.outputs:
            res += "    " + o.name + f"_i_{o.get_input_index(c)} <= ("

            for val in c.c:
                res += "\"" + int_to_std_logic_vector(val) + "\", "

            res = res[:-2]

            res += ");\n"

    return res

def int_to_std_logic_vector(val: int, data_width: int = 16, decimal_place = 1, sign: bool = True):
    neg = val < 0

    start = 2
    if neg:
        start = 3

    if sign:
        decimal_place -= 1

    res = bin(int(val))[start:]

    if len(res) > decimal_place:
        res = ""
        for _ in range(decimal_place):
            res += "1"
    else:
        for _ in range(decimal_place - len(res)):
            res = "0" + res

    if sign:
        res = "0" + res

    val = val - int(val)

    for _ in range(data_width - decimal_place):
        val *= 2

        if int(val) == 1:
            res += "1"
            val -= 1
        else:
            res += "0"

    if sign and neg:
        res_inv = ""
        for c in res:
            if c == "1":
                res_inv += "0"
            else:
                res_inv += "1"
        res = res_inv

    return res
