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
                res += get_entities(params)
            elif l.startswith("-- CONSTANT"):
                res += get_constant(model)
            else:
                res += l

    return res

def get_states(params: ModelParams) -> str:
    return f"    constant num_states : positive := {len(params.operations)};\n    signal state, next_state : integer;\n"

def get_signals(model: Model) -> str:
    res = ""
    START = "    signal "

    for sn,sw in model.generate_signals():
        if sw > 1:
            res += START + sn + f" : array_type({sw - 1} downto 0)(data_width-1 downto 0);\n"
        else:
            res += START + sn + ": std_logic_vector(data_width-1 downto 0);\n"

    return res

def get_fsm(params: ModelParams) -> str:
    res = ""

    for i, n in enumerate(params.operations):
        connection, should_handshake = n.generate_connections()

        res += f"            when {i+1} =>\n"
        res += connection
        if not should_handshake or i == 0:
            res += "                next_state <= state + 1;\n"
        else:
            res += "                if valid_in then\n"
            res += "                    valid_out <= '0';\n"
            res += "                    was_valid <= '1';\n"
            res += "                elsif was_valid then\n"
            res += "                    was_valid <= '0';\n"
            if i == len(params.operations):
                res += "                    next_state <= state + 1;\n"
            else:
                res += "                    next_state <= 0;\n"
            res += "                end if;\n"

    return res

def get_entities(params: ModelParams) -> str:
    res = ""

    for n in params.operations:
        res += n.to_vhdl_entity(16)

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

def int_to_std_logic_vector(val: float, data_width: int = 16, decimal_place = 1, signed: bool = True):
    val *= 1 << (data_width - decimal_place)

    max_val = 1 << data_width if not signed else 1 << (data_width - 1)

    if val >= max_val:
        return "1" * data_width if not signed else "0" + ("1" * (data_width - 1))
    if val < -max_val:
        return "1" + ("0" * (data_width - 1))

    val = int(val)
    res = bin(val if val > 0 or not signed else val + (1 << data_width))[2:]
    return ("0" * (data_width - len(res))) + res
