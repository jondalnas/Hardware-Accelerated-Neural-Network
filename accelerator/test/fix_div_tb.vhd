----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.06.2024 19:03:39
-- Design Name: 
-- Module Name: fix_div_tb - Behavioral
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
use work.defs.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fix_div_tb is
end fix_div_tb;

architecture div_test of fix_div_tb is
    signal dividend : signed(15 downto 0);
    signal divisor : signed(15 downto 0);
    signal res : signed(15 downto 0);

begin
    
    dut : entity work.fix_div
    generic map (
        data_width => DATA_WIDTH
    )
    port map (
        dividend => dividend,
        divisor => divisor,
        res => res
    );
    
    process
    
    begin
        dividend <= "0010000000000000";
        divisor <= "0100000000000000";
        wait for 200 ns;
        
        
        dividend <= "0000110000000000";
        divisor <=  "0110110000000000";
        wait for 200 ns;
        
    end process;

end div_test;
