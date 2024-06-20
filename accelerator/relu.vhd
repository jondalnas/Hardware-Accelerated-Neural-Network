library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity relu is
    generic (
        input_size : integer;
        data_width : integer
    );
    Port ( 
        x : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(input_size - 1 downto 0)(data_width - 1 downto 0)
    );
end relu;

architecture Behavioral of relu is
begin
    relu_gen : for i in 0 to input_size - 1 generate
        y(i) <= x(i) when x(i)(data_width - 1) = '0' else (others => '0');
    end generate;
end Behavioral;
