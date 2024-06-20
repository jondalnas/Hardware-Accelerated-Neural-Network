library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity div is
    generic (
        input_size : integer;
        data_width : integer
    );
    Port ( 
        a : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        b : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        c : out array_type(input_size - 1 downto 0)(data_width - 1 downto 0)
    );
end div;

architecture Behavioral of div is

begin

    arr_div_gen : for i in 0 to input_size - 1 generate
        div: entity work.fix_div
        generic map (
            data_width => data_width
        )
        port map (
            dividend => a(i),
            divisor => b(i),
            res => c(i)
        );
    end generate;

end Behavioral;
