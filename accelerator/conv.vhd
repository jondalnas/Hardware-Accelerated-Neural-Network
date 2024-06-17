----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.06.2024 15:39:09
-- Design Name: 
-- Module Name: conv - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
