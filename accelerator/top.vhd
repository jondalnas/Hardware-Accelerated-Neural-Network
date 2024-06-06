----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.06.2024 14:20:52
-- Design Name: 
-- Module Name: top - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    port(
        clk_100mhz : in  std_logic;
        rst        : in  std_logic;
        led        : out std_logic;
        start      : in  std_logic;
        -- Serial interface for PC communication
        serial_tx  : in  STD_LOGIC;     -- from the PC
        serial_rx  : out STD_LOGIC      -- to the PC
    );
end top;

architecture Behavioral of top is

begin


end Behavioral;
