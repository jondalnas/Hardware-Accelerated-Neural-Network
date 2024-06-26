library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

package defs is
-- INSTRUCTIONS
-- INPUT SIZE
    constant DATA_WIDTH : Integer := 16;
    constant INTEGER_WIDTH : Integer := 8;
    constant DECIMAL_WIDTH : Integer := DATA_WIDTH - INTEGER_WIDTH;
    constant INST_SIZE : Integer := 3;
-- NN SIZES
end defs;
