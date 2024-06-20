library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.types.all;

entity max_tb is
end max_tb;

architecture tb of max_tb is
	signal a : array_type(10 downto 0)(15 downto 0);
	signal c : signed(15 downto 0);
begin
	dut : entity work.max
		generic map(
			data_width => 16,
			num_inputs => 11)
		port map(
			a => a,
			c => c
		);
	
	process
	    variable m : signed(15 downto 0);
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
		for i in 0 to 10 loop
			a(i) <= signed(rand_slv(16));
		end loop;

		wait for 1 ns;

		m := (others => '0');
		for i in 0 to 10 loop
			m := maximum(m, to_integer(a(i)));
		end loop;

		assert c = m report "Error: Sum (" & to_hstring(m) & ") not mathcing inputs" severity error;

	   wait for 1 ns;
	end process;
end tb;
