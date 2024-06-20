library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

package defs is
    constant INPUT_SIZE : integer := 4;
    constant INSTRUCTIONS : array_type(4 downto 0)(18 downto 0) := ("0000000000000010001", "0000000000000010010", "0000000000000010001", "0000000000000010010", "0000000000000010000");
    constant DATA_WIDTH : integer := 16;
    constant INTEGER_WIDTH : integer := 1;
    constant DECIMAL_WIDTH : integer := DATA_WIDTH - INTEGER_WIDTH;
    constant INST_SIZE : Integer := 3;
end defs;
