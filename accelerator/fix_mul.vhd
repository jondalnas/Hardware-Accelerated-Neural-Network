----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.06.2024 12:50:32
-- Design Name: 
-- Module Name: fix_mul - Behavioral
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

entity fix_mul is
    generic (
        data_width : integer
    );
    Port (
        a : in std_logic_vector(data_width - 1 downto 0);
        b : in std_logic_vector(data_width - 1 downto 0);
        res : out std_logic_vector(data_width - 1 downto 0)
     );
end fix_mul;

architecture Behavioral of fix_mul is

begin


end Behavioral;
