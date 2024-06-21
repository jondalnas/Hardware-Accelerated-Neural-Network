library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

package defs is
    constant INSTRUCTIONS : instr_type(1 downto 0)(18 downto 0) := ("0000000001010010", "0000000000000000");
    constant INPUT_SIZE : Integer := 784;
    constant DATA_WIDTH : Integer := 16;
    constant INTEGER_WIDTH : Integer := 1;
    constant DECIMAL_WIDTH : Integer := DATA_WIDTH - INTEGER_WIDTH;
    constant INST_SIZE : Integer := 3;
    constant NN_INPUT : Integer := 784;
    constant NN_OUTPUT : Integer := 10;
    constant NN_FEEDBACK : Integer := 6272;
end defs;
