library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

entity broad is
    generic (
        input_size : integer;
        output_size : integer;
        data_width : integer
    );
    Port (
        input : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        output : out array_type(output_size - 1 downto 0)(data_width - 1 downto 0)
    );
end broad;

architecture Behavioral of broad is
begin
	l : for i in 0 to output_size / input_size - 1 generate
		output((i + 1) * input_size - 1 downto i * input_size) <= input;
	end generate;
end Behavioral;
