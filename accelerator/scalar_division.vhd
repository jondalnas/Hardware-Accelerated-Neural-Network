----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.06.2024 18:33:22
-- Design Name: 
-- Module Name: scalar_division - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity scalar_division is
    generic (
        scalar : std_logic_vector(15 downto 0);
        input_size : integer;
        output_size : integer
    );
    Port (
        input : in std_logic_vector(input_size - 1 downto 0);
        output : out std_logic_vector(output_size - 1 downto 0)
    );
end scalar_division;

architecture Behavioral of scalar_division is

begin


end Behavioral;
