library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

use work.types.all;

entity conv is
    generic( 
        num_dimensions : integer;
        dimensions_x : dimensions_type(num_dimensions - 1 downto 0);
        x_size : integer;
        dimensions_w : dimensions_type(num_dimensions - 1 downto 0);
        w_size : integer;
        kernel_shape : dimensions_type(num_dimensions - 3 downto 0);
		kernel_size : integer;
        dilation : dimensions_type(num_dimensions - 3 downto 0);
        stride : dimensions_type(num_dimensions - 3 downto 0);
        data_width : integer;
        y_size : integer
    );
    Port (
        x : in array_type(x_size - 1 downto 0)(data_width - 1 downto 0);
        w : in array_type(w_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(y_size - 1 downto 0)(data_width - 1 downto 0)
     );
end conv;

architecture Behavioral of conv is
	type res_array is array(y_size - 1 downto 0) of array_type(kernel_size - 1 downto 0)(data_width - 1 downto 0);
	signal res : res_array;

	constant x_offs : integer := integer(ceil(real(kernel_shape(0) * dilation(0) - (dilation(0) - 1)) / 2)) - 1;
	constant y_offs : integer := integer(ceil(real(kernel_shape(1) * dilation(1) - (dilation(1) - 1)) / 2)) - 1;
begin
	dim2 : if num_dimensions = 4 generate
		--Assuming no layers to input image, might be wrong

		-- Color channel loop
		cl : for cc in 0 to dimensions_x(2) - 1 generate
			-- Dimension loops
			yl : for yy in 0 to dimensions_x(1) - 1 generate
				xl : for xx in 0 to dimensions_x(0) - 1 generate

					-- Kernel loop
					lk : for llk in 0 to dimensions_w(3) - 1 generate
						yk : for yyk in 0 to kernel_shape(1) - 1 generate
							xk : for xxk in 0 to kernel_shape(0) - 1 generate
								-- If OOB, set element to 0
								oob : if (yy * stride(1) + yyk * dilation(1) - y_offs < 0) or (xx * stride(0) + xxk * dilation(0) - x_offs < 0) or (yy * stride(1) + yyk * dilation(1) - y_offs >= dimensions_x(1)) or (xx * stride(0) + xxk * dilation(0) - x_offs >= dimensions_x(0)) generate
									res(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))(xxk + yyk * kernel_shape(0)) <= (others => '0');
								else generate
									mul : entity work.fix_mul
										generic map(
											data_width => 16
										)
										port map(
											a => x((xx * stride(0) + xxk * dilation(0) - x_offs) + (yy * stride(1) + yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)),
											b => w(xxk + yyk * dimensions_w(0) + cc * dimensions_w(0) * dimensions_w(1) + llk * dimensions_w(0) * dimensions_w(1) * dimensions_w(2)),
											res => res(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1))
										);
								end generate;
							end generate;
						end generate;

						sum : entity work.sum
							generic map(
								data_width => data_width,
								num_inputs => kernel_size
							)
							port map(
								a => res(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1)),
								c => y(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))
							);
					end generate;
				end generate;
			end generate;
		end generate;
	end generate;
end Behavioral;
