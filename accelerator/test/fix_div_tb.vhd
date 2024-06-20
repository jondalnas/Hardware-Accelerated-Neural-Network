library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.defs.all;

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
