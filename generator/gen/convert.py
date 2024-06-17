"""Convert onnyx model tree into VHDL file"""

from math import log2

from .loader import Model

def convert_model(model: Model) -> str:
    res = ""

    with open("template.vhd", 'r', encoding="utf-8") as f:
        for l in f:
            if l.startswith("-- STATES"):
                res += get_states(model)
            elif l.startswith("-- SIGNALS"):
                res += get_signals(model)
            elif l.startswith("-- FSM"):
                res += get_fsm(model)
            elif l.startswith("-- ENTITIES"):
                res += get_entities(model)
            else:
                res += l

    return res

def get_states(model: Model) -> str:
    num_states = len(model.nodes) - len(model.inputs) - len(model.outputs) - len(model.constants)
    return "    constant num_states : positive := {};\n    signal state, next_state : std_logic_vector({} downto 0);\n".format(num_states, int(log2(num_states+1) - 1))

def get_signals(model: Model) -> str:
    res = ""
    START = "    signals "

    for sn,sw in model.generate_signals():
        res += START + sn + " : array_type({} downto 0)(data_width-1 downto 0);\n".format(sw)

    return res

def get_fsm(model: Model) -> str:
    res = ""
    num_states = len(model.nodes) - len(model.inputs) - len(model.outputs) - len(model.constants)

    p, max_fb = model.calc_instruction_list()

    print(p)
    print(max_fb)

    for i in range(1, num_states):
        res += "            when {}:\n".format(i)
        res += "                next_state <= state + 1;\n"

    return (res + f"            when {num_states}:\n"
                 "                if valid_in then\n"
                 "                    valid_out <= '0';\n"
                 "                    was_valid <= '1';\n"
                 "                elsif was_valid then\n"
                 "                    was_valid <= '0'\n"
                 "                    next_state <= 0;\n"
                 "                 end if;\n")

def get_entities(model: Model) -> str:
    res = ""

    for n in model.nodes:
        res += ""# n.to_vhdl_entity()

    return res
