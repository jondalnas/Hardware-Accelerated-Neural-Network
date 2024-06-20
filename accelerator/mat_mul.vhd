library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity mat_mul is
    generic (
        num_dimensions : integer;
        a_dim : dimensions_type(num_dimensions - 1 downto 0);
        b_dim : dimensions_type(num_dimensions - 1 downto 0);
        a_size : integer;
        b_size : integer;
        y_size : integer;
        data_width : integer
    );
    Port (
        a : in array_type(a_size - 1 downto 0)(data_width - 1 downto 0);
        b : in array_type(b_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(y_size - 1 downto 0)(data_width - 1 downto 0)
     );
end mat_mul;

architecture Behavioral of mat_mul is

begin


end Behavioral;
