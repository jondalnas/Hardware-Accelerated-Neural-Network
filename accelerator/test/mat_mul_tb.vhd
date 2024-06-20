library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.types.all;

entity mat_mul_tb is
end mat_mul_tb;

architecture tb of mat_mul_tb is
	signal a : array_type(5 downto 0)(15 downto 0);
	signal b : array_type(5 downto 0)(15 downto 0);
	signal c : array_type(3 downto 0)(15 downto 0);
begin
	dut : entity work.mat_mul
		generic map(
			data_width => 16,
			num_dimensions => 2,
			a_size => 6,
			b_size => 6,
			y_size => 4,
			a_dim => (2, 3),
			b_dim => (3, 2)
		)
		port map(
			a => a,
			b => b,
			y => c
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
		a <= ("0100000000000000", "0010000000000000", "0100000000000000",
		      "0001000000000000", "0100000000000000", "0001000000000000");
		      
		b <= ("0100000000000000", "0010000000000000",
		      "0100000000000000", "0001000000000000",
		      "0100000000000000", "0001000000000000");

		wait for 1 ns;
	end process;
end tb;
