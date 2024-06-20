library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity fix_mul_tb is
end fix_mul_tb;

architecture tb of fix_mul_tb is
	signal a, b, c : std_logic_vector(15 downto 0);
begin
	dut : entity work.fix_mul
		generic map(data_width => 16)
		port map(
			a => a,
			b => b,
			res => c
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
		a <= rand_slv(16);
		b <= rand_slv(16);
		wait for 1 ns;
--		assert c = std_logic_vector(to_signed(integer(((real(to_integer(unsigned(a))) / (2 ** 15)) * (real(to_integer(unsigned(a))) / (2 ** 15))) * 2 ** 15), 16)) report "Error: Input and output does not match" severity error;
	end process;
end tb;
