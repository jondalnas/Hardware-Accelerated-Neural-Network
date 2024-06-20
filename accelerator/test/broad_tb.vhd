library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.types.all;

entity broad_tb is
end broad_tb;

architecture tb of broad_tb is
	signal input : array_type(7 downto 0)(15 downto 0);
	signal output : array_type(15 downto 0)(15 downto 0);
begin
	dut : entity work.broad
		generic map(
			data_width => 16,
			output_size => 16,
			input_size => 8
		)
		port map(
			input => input,
			output => output
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
		for i in 0 to 7 loop
			input(i) <= rand_slv(16);
		end loop;

		wait for 1 ns;

		assert output = (input & input) report "Error: Concatination failed" severity error;

	   wait for 1 ns;
	end process;
end tb;
