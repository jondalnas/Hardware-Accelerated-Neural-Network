library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.defs.all;
use work.types.all;

entity max_pool_tb is
end max_pool_tb;

architecture max_pool_test of max_pool_tb is

    signal x : array_type((1*1*4*4) - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    signal y : array_type((1*1*2*2) - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    signal clk, rst, valid_in, valid_out : std_logic := '0';

begin
    clk <= not clk after 500 ns;

    max : entity work.max_pool
    generic map(
        num_dimensions => 4,
        kernel_shape => (2,2),
        pads => (0,0,0,0),
        strides => (2,2),
        in_dimensions => (1,1,4,4),
        out_dimensions => (1,1,2,2),
        input_size => 1 * 1 * 4 * 4,
        output_size => 1*1*2*2,
        data_width => DATA_WIDTH
    )
    port map(
        clk => clk,
        rst => rst,
        valid_in => valid_in,
        valid_out => valid_out,
        x => x,
        y => y
    );
    
    process
    begin
        rst <= '1';
        wait for 500 ns;
        rst <= '0';
        wait for 500 ns;
        for i in 0 to (1*1*4*4) - 1 loop
            x(i) <= to_signed(5 + i, DATA_WIDTH);
        end loop;
        valid_in <= '1';
        wait until valid_out = '1';
        valid_in <= '0';
    end process;

end max_pool_test;
