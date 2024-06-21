library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.types.all;

entity add is
    generic (
        input_size : integer;
        data_width : integer
    );
    Port ( 
		clk : in std_logic;
		rst : in std_logic;
		valid_in : in std_logic;
		valid_out : out std_logic;
        a : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        b : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        c : out array_type(input_size - 1 downto 0)(data_width - 1 downto 0)
    );
end add;

architecture Behavioral of add is

begin
    add_gen : for i in 0 to input_size - 1 generate
        c(i) <= a(i) + b(i);
    end generate;

end Behavioral;
