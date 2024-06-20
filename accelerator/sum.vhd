library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use ieee.numeric_std.all;

use work.types.all;
use work.defs.all;

entity sum is
	generic(
		data_width : integer := 16;
		num_inputs : integer
	);
	port(
		a : in array_type(num_inputs - 1 downto 0)(data_width - 1 downto 0);
		c : out signed(data_width - 1 downto 0)
	);
end sum;

architecture sum_behaviorial of sum is
    signal c1, c2 : signed(data_width - 1 downto 0);
    
    constant half_lower : integer := num_inputs / 2;
    constant half_upper : integer := num_inputs - half_lower;
begin
	eq1 : if num_inputs = 1 generate
		c <= a(0);
	else generate
		s1 : entity work.sum
			generic map(
				data_width => data_width,
				num_inputs => half_upper
			)
			port map(
				a => a(num_inputs - 1 downto half_lower),
				c => c1
			);
		s2 : entity work.sum
			generic map(
				data_width => data_width,
				num_inputs => half_lower
			)
			port map(
				a => a(half_lower - 1 downto 0),
				c => c2
			);
		c <= c1 + c2;
	end generate;
end architecture;
