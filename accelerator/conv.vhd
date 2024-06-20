library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity conv is
    generic( 
        num_dimensions : integer;
        dimensions_x : dimensions_type(num_dimensions - 1 downto 0);
        x_size : integer;
        dimensions_w : dimensions_type(num_dimensions - 1 downto 0);
        w_size : integer;
        kernel_shape : dimensions_type(num_dimensions - 1 downto 0);
        dilation : dimensions_type(num_dimensions - 1 downto 0);
        stride : dimensions_type(num_dimensions - 1 downto 0);
        data_width : integer;
        y_size : integer
    );
    Port (
        x : in array_type(x_size - 1 downto 0)(data_width - 1 downto 0);
        w : in array_type(w_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(y_size - 1 downto 0)(data_width - 1 downto 0)
     );
end conv;

architecture Behavioral of conv is

begin


end Behavioral;
