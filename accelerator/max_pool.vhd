library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity max_pool is
    generic(
        num_dimensions : integer;
        kernel_shape : dimensions_type(num_dimensions - 1 downto 0);
        pads : dimensions_type(2 * num_dimensions - 1 downto 0);
        strides : dimensions_type(num_dimensions- 1 downto 0);
        in_dimensions : dimensions_type(num_dimensions- 1 downto 0);
        input_size : integer;
        output_size : integer;
        data_width : integer
    );
    Port (
        x : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(output_size - 1 downto 0)(data_width - 1 downto 0)
     );
end max_pool;

architecture Behavioral of max_pool is

begin


end Behavioral;
