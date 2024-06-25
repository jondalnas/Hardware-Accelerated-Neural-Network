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
	signal clk, rst, valid_in, valid_out : std_logic := '0';
begin
    clk <= not clk after 500 ns;

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
            dilation => (1, 1),
            stride => (1, 1)
        )
        port map(
            clk => clk,
            rst => rst,
            valid_in => valid_in,
            valid_out => valid_out,
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
	   rst <= '1';
	   wait for 500 ns;
	   rst <= '0';
	   wait for 500 ns;
	   
		x <= ("0000000000000100", "0000000000100000", "0000000000100000",
		      "0000000000000101", "0000000000000010", "0000000010000000",
		      "0000000010000100", "0000000000000100", "0000000000010000");
		      -- x = [[0.0634765625, 0.01568603515625, 0.515625], [0.5009765625, 0.00830078125, 0.017578125], [0.1259765625, 0.125, 0.015625]]
		      -- x = "0000001000000000", "0001000000000000", "0001000000100000",
        --	         "0000001001000000", "0000000100010000", "0100000000100000",
        --		     "0100001000000000", "0000001000000010", "0000100000100000"
		
		w <= ("0000000000100000", "0000000001000000", "0000000000100000",
		      "0000000001000000", "0000000010000000", "0000000001000000",
		      "0000000000100000", "0000000001000000", "0000000000100000",
		      
		      "0000000000100000", "0000000000110000", "0000000000100000",
		      "0000000000110000", "0000000000001100", "0000000000110000",
		      "0000000000100000", "0000000000110000", "0000000000100000");      
--		w <= ("0001000000000000", "0010000000000000", "0001000000000000",
--		      "0010000000000000", "0100000000000000", "0010000000000000",
--		      "0001000000000000", "0010000000000000", "0001000000000000",
		      
--		      "0001000000000000", "0001100000000000", "0001000000000000",
--		      "0001100000000000", "0000011000000000", "0001100000000000",
--		      "0001000000000000", "0001100000000000", "0001000000000000");
		      -- w = [[[0.125, 0.1875, 0.125], [0.1875, 0.046875, 0.1875], [0.125, 0.1875, 0.125]], [[0.125, 0.25, 0.125], [0.25, 0.5, 0.25], [0.125, 0.25, 0.125]]]
               
              --out[0] = [[0cea , 167d, 0406],[0a01, 1b67, 0f4e],[0fe9, 0ca5 , 03a6]]
              --out[1] = [[14bb, 1c19, 2233],[28a4, 2128, 14a4],[1c3a, 1518, 05b2]]

        valid_in <= '1';
		wait until valid_out = '1';
		valid_in <= '0';
		
	end process;
end tb;
