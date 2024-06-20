----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.06.2024 15:39:09
-- Design Name: 
-- Module Name: add - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity add is
    generic (
        input_size : integer;
        data_width : integer
    );
    Port ( 
        a : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        b : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        c : out array_type(input_size - 1 downto 0)(data_width - 1 downto 0)
    );
end add;

architecture Behavioral of add is

begin
    add_gen : for i in 0 to input_size - 1 generate
        c(i) <= std_logic_vector(signed(a(i)) + signed(b(i)));
    end generate;

end Behavioral;
