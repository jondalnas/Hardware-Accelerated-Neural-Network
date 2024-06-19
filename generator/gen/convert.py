"""Convert onnyx model tree into VHDL file"""

from math import log2

from .loader import Model, ModelParams

def convert_model(model: Model) -> tuple[str, str]:
    nn = ""
    defs = ""

    params = model.calc_model_params()

    with open("nn_template.vhd", 'r', encoding="utf-8") as f:
        for l in f:
            if l.startswith("-- STATES"):
                nn += get_states(params)
            elif l.startswith("-- SIGNALS"):
                nn += get_signals(model)
            elif l.startswith("-- FSM"):
                nn += get_fsm(params)
            elif l.startswith("-- ENTITIES"):
                nn += get_entities(params)
            elif l.startswith("-- CONSTANT"):
                nn += get_constant(model)
            else:
                nn += l

    with open("defs_template.vhd", 'r', encoding="utf-8") as f:
        for l in f:
            if l.startswith("-- INSTRUCTIONS"):
                defs += get_instructions(params)
            elif l.startswith("-- INPUT SIZE"):
                defs += get_input_size(params)
            else:
                defs += l

    return (nn, defs)

def get_states(params: ModelParams) -> str:
    return "    signal state, next_state : integer;\n"

def get_signals(model: Model) -> str:
    res = ""
    START = "    signal "

    for sn,sw in model.generate_signals():
        res += START + sn + f" : array_type({sw - 1} downto 0)(data_width-1 downto 0);\n"

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

    BROADCAST = ("    {}_bc : entity work.broad\n"
                 "        generic map(\n"
                 "            input_size => {},\n"
                 "            output_size => {},\n"
                 "            data_width => {}\n"
                 "        )\n"
                 "        port map(\n"
                 "            input => {},\n"
                 "            output => {}\n"
                 "        );\n")

    for n in params.operations:
        res += n.to_vhdl_entity(16)

        for index, input_size, output_size in n.get_intput_broadcasts():
            res += BROADCAST.format(n.name + "_" + str(index), input_size, output_size, 16, n.name + f"_i_{index}", n.name + f"_bc_i_{index}")

    return res

def get_constant(model: Model) -> str:
    res = ""

    for c in model.constants:
        for o in c.outputs:
            res += "    " + o.name + f"_i_{o.get_input_index(c)} <= ("

            if len(c.c) == 1:
                res += "0 => \"" + int_to_std_logic_vector(c.c[0]) + "\");\n"
                continue

            for val in c.c:
                res += "\"" + int_to_std_logic_vector(val) + "\", "

            res = res[:-2]

            res += ");\n"

    return res

def get_instructions(params: ModelParams) -> str:
    res = f"    constant INSTRUCTIONS : array_type({len(params.mem_instructions) - 1} downto 0)(18 downto 0) := ("

    for mi, num in reversed(params.mem_instructions):
        print(mi.value, num)
        res += "\"" + int_to_std_logic_vector(mi.value[0] + (num << 3), decimal_place=16, signed=False) + "\", "

    res = res[:-2] + ");\n"

    return res

def get_input_size(param: ModelParams) -> str:
    return f"    constant INPUT_SIZE : Integer := {param.nn_input_size};\n"

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
