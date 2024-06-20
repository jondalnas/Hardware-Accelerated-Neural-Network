library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.types.all;

entity conv_tb is
end conv_tb;

architecture tb of conv_tb is
	signal x : array_type(8 downto 0)(15 downto 0);
	signal w : array_type(17 downto 0)(15 downto 0);
	signal y : array_type(17 downto 0)(15 downto 0);
begin
	dut : entity work.conv
		generic map(
			data_width => 16,
			num_dimensions => 4,
			x_size => 9,
			w_size => 18,
			y_size => 18,
			kernel_size => 9,
			dimensions_x => (1, 1, 3, 3),
			dimensions_w => (2, 1, 3, 3),
			kernel_shape => (3, 3),
			dilation => (0, 0),
			stride => (1, 1)
		)
		port map(
			x => x,
			w => w,
			y => y
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
		x <= ("0100000000000000", "0100000000000000", "0100000000000000",
		      "0100000000000000", "0100000000000000", "0100000000000000",
		      "0100000000000000", "0100000000000000", "0100000000000000");
		      
		w <= ("0001000000000000", "0010000000000000", "0001000000000000",
		      "0010000000000000", "0100000000000000", "0010000000000000",
		      "0001000000000000", "0010000000000000", "0001000000000000",
		      
		      "0001000000000000", "0001100000000000", "0001000000000000",
		      "0001100000000000", "0000011000000000", "0001100000000000",
		      "0001000000000000", "0001100000000000", "0001000000000000");

		wait for 1 ns;
	end process;
end tb;
