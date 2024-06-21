library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity mat_mul is
    generic (
        num_dimensions : integer;
        a_dim : dimensions_type(num_dimensions - 1 downto 0);
        b_dim : dimensions_type(num_dimensions - 1 downto 0);
        a_size : integer;
        b_size : integer;
        y_size : integer;
        data_width : integer
    );
    Port (
		clk : in std_logic;
		rst : in std_logic;
		valid_in : in std_logic;
		valid_out : out std_logic;
        a : in array_type(a_size - 1 downto 0)(data_width - 1 downto 0);
        b : in array_type(b_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(y_size - 1 downto 0)(data_width - 1 downto 0)
     );
end mat_mul;

architecture Behavioral of mat_mul is
	type res_array is array(y_size - 1 downto 0) of array_type(a_dim(0) - 1 downto 0)(data_width - 1 downto 0);
	signal res : res_array;
begin
	dim2 : if num_dimensions = 2 generate
		yl : for yy in 0 to a_dim(1) - 1 generate
			xl : for xx in 0 to b_dim(0) - 1 generate
				il : for i in 0 to a_dim(0) - 1 generate
					mul : entity work.fix_mul
						generic map(data_width => data_width)
						port map(
							a => a(i + yy * a_dim(0)),
							b => b(xx + i * b_dim(0)),
							res => res(xx + yy * b_dim(0))(i)
						);
				end generate;

				sum : entity work.sum
					generic map(
						data_width => data_width,
						num_inputs => a_dim(0)
					)
					port map(
						a => res(xx + yy * b_dim(0)),
						c => y(xx + yy * b_dim(0))
					);
			end generate;
		end generate;
	end generate;
end Behavioral;
