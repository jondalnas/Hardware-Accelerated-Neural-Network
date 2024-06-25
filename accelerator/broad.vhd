library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

entity broad is
    generic (
        input_size : integer;
        block_repeat : integer;
        element_repeat : integer;
        data_width : integer
    );
    Port (
        input : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        output : out array_type(input_size * element_repeat * block_repeat - 1 downto 0)(data_width - 1 downto 0)
    );
end broad;

architecture Behavioral of broad is
 
    
begin
	l : for i in 0 to block_repeat - 1 generate
        il : for inp in 0 to input_size - 1 generate
            el : for j in 0 to element_repeat - 1 generate
              output(j + inp * element_repeat + i * input_size * element_repeat) <= input(inp);
            end generate;
		end generate;
	end generate;
end Behavioral;
