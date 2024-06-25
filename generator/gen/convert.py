"""Convert onnyx model tree into VHDL file"""

from math import log2

from .loader import Model, ModelParams, ConstNode

def convert_model(model: Model) -> tuple[str, str]:
    nn = ""
    defs = ""

    params = model.calc_model_params()

    with open("nn_template.vhd", 'r', encoding="utf-8") as f:
        for l in f:
            if l.startswith("-- STATES"):
                nn += get_states(params)
            elif l.startswith("-- SIGNALS"):
                nn += get_signals(model, params)
            elif l.startswith("-- FSM"):
                nn += get_fsm(params)
            elif l.startswith("-- ENTITIES"):
                nn += get_entities(params)
            elif l.startswith("-- CONSTANT"):
                nn += get_constant(model)
            elif l.startswith("-- INIT SIGNALS"):
                nn += get_init_signals(params)
            else:
                nn += l

    with open("defs_template.vhd", 'r', encoding="utf-8") as f:
        for l in f:
            if l.startswith("-- INSTRUCTIONS"):
                defs += get_instructions(params)
            elif l.startswith("-- INPUT SIZE"):
                defs += get_input_size(params)
            elif l.startswith("-- NN SIZES"):
                defs += get_nn_sizes(params)
            else:
                defs += l

    return (nn, defs)

def get_states(params: ModelParams) -> str:
    return "    signal state, next_state : integer;\n"

def get_signals(model: Model, params: ModelParams) -> str:
    res = ""
    START = "    signal "

    for sn,sw in model.generate_signals():
        res += START + sn + f" : array_type({sw - 1} downto 0)(data_width-1 downto 0);\n"

    res += START
    for n in params.operations:
        res += n.name + "_valid_in, " + n.name + "_valid_out, "

    res = res[:-2] + " : std_logic;\n"

    return res

def get_fsm(params: ModelParams) -> str:
    res = ""

    for i, n in enumerate(params.operations):
        connection, output_connection, should_handshake = n.generate_connections()

        if i == len(params.operations) - 1:
            res += "            when others =>\n"
        else:
            res += f"            when {i+1} =>\n"

        res += connection
        res += "                " + n.name + "_valid_in <= '1';\n"
        if not should_handshake or i == 0:
            res +=  "                if " + n.name + "_valid_out then\n"
            res += f"                    next_state <= {i + 2};\n"
            res += output_connection
            res +=  "                end if;\n"
        else:
            res += "                valid_out <= " + n.name + "_valid_out;\n"
            res += "                if not valid_in then\n"
            res += "                    next_was_valid <= '0';\n"
            res += "                    valid_out <= '0';\n"
            res += "                elsif not was_valid then\n"
            res += "                    next_was_valid <= '1';\n"
            if i == len(params.operations) - 1:
                res += "                    next_state <= 0;\n"
            else:
                res += f"                    next_state <= {i + 2};\n"
            res += output_connection
            res += "                end if;\n"

    return res

def get_init_signals(params: ModelParams) -> str:
    res = ""

    for n in params.operations:
        for i, input_node in enumerate(n.get_inputs()):
            if isinstance(input_node, ConstNode):
                continue

            res += "        " + n.name + f"_i_{i} <= (others => (others => '0'));\n"

        res += "        " + n.name + "_valid_in <= '0';\n"

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

        for index, input_size, output_size in n.get_input_broadcasts():
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

            for val in reversed(c.c):
                res += "\"" + int_to_std_logic_vector(val) + "\", "

            res = res[:-2]

            res += ");\n"

    return res

def get_instructions(params: ModelParams) -> str:
    res = f"    constant INSTRUCTIONS : instr_type({len(params.mem_instructions) - 1} downto 0)(18 downto 0) := ("

    for mi, num in reversed(params.mem_instructions):
        print(mi.value, num)
        res += "\"" + int_to_std_logic_vector(mi.value[0] + (num << 3), data_width=19, decimal_place=19, signed=False) + "\", "

    res = res[:-2] + ");\n"

    return res

def get_input_size(params: ModelParams) -> str:
    return (f"    constant INPUT_SIZE : Integer := {params.nn_input_size};\n"
            f"    constant OUTPUT_SIZE : Integer := {params.nn_output_size};\n")

def get_nn_sizes(params: ModelParams) -> str:
    return (f"    constant NN_INPUT : Integer := {params.max_input};\n"
            f"    constant NN_OUTPUT : Integer := {params.max_output};\n"
            f"    constant NN_FEEDBACK : Integer := {params.max_feedback};\n")

def int_to_std_logic_vector(val: float, data_width: int = 16, decimal_place = 8, signed: bool = True):
    val *= 1 << (data_width - decimal_place)

    max_val = 1 << data_width if not signed else 1 << (data_width - 1)

    if val >= max_val:
        return "1" * data_width if not signed else "0" + ("1" * (data_width - 1))
    if val < -max_val:
        return "1" + ("0" * (data_width - 1))

    val = int(val)
    res = bin(val if val >= 0 or not signed else val + (1 << data_width))[2:]
    return ("0" * (data_width - len(res))) + res
