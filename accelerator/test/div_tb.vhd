library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;


use work.types.all;
use work.defs.all;

entity div_tb is
end div_tb;

architecture div_test of div_tb is
    signal a, b, c : array_type(5 downto 0)(DATA_WIDTH - 1 downto 0);
    
	signal clk, rst, valid_in, valid_out : std_logic := '0';
begin
	clk <= not clk after 100 ns;

    div : entity work.div
        generic map(
            input_size => 6,
            data_width => DATA_WIDTH
        )
        port map (
			clk => clk,
			rst => rst,
			valid_in => valid_in,
			valid_out => valid_out,
            a => a,
            b => b,
            c => c
        );
        
        
    process    
        variable seed1, seed2 : integer := 999;
        
        impure function rand_slv(len : integer) return std_logic_vector is
            variable r : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
                uniform(seed1, seed2, r);
                if r > 0.5 then 
                    slv(i) := '1';
                else
                    slv(i) := '0';
                end if;
            end loop;
            return slv;
        end function;
    begin
		rst <= '1';
		wait for 200 ns;
		rst <= '0';

        for i in 0 to 5 loop
            a(i) <= signed(rand_slv(DATA_WIDTH));
            b(i) <= signed(rand_slv(DATA_WIDTH));
        end loop;
		valid_in <= '1';
        
        wait until valid_out = '1';
		valid_in <= '0';

		wait until valid_out = '0';
    end process;
end div_test;
