library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.types.all;

entity max_pool is
    generic(
        num_dimensions : integer;
        kernel_shape : dimensions_type(num_dimensions - 3 downto 0);
        pads : dimensions_type(2 * (num_dimensions - 2) - 1 downto 0);
        strides : dimensions_type(num_dimensions - 3 downto 0);
        in_dimensions : dimensions_type(num_dimensions - 1 downto 0);
        out_dimensions : dimensions_type(num_dimensions - 1 downto 0);
        input_size : integer;
        output_size : integer;
        data_width : integer
    );
    Port (
        x : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(output_size - 1 downto 0)(data_width - 1 downto 0)
     );
end max_pool;

architecture Behavioral of max_pool is
    type kernel_array_type is array(0 to output_size - 1) of array_type(0 to kernel_shape(0) * kernel_shape(1) - 1)(data_width - 1 downto 0);
    signal kernels : kernel_array_type;
    
    constant x_offs : integer := integer(ceil(real(kernel_shape(0)) / 2.0)) - 1;
    constant y_offs : integer := integer(ceil(real(kernel_shape(1)) / 2.0)) - 1;
    --TODO : add padding and strides

begin
    im_gen : if num_dimensions = 4 generate -- Generate hardware for the specific 4 dimension case
        batch_gen : for n in 0 to in_dimensions(3) - 1 generate
            channel_gen : for c in 0 to in_dimensions(2) - 1 generate
                y_gen : for yy in 0 to out_dimensions(1) - 1 generate
                    x_gen : for xx in 0 to out_dimensions(0) - 1 generate
                        kern_y_gen : for ky in 0 to kernel_shape(1) - 1 generate
                            kern_x_gen : for kx in 0 to kernel_shape(0) - 1 generate
                                oob : if (yy*strides(1) + ky - y_offs < 0) or (xx*strides(0) + kx - x_offs < 0) or (yy*strides(1) + ky - y_offs >= in_dimensions(0)) or (xx*strides(0) + kx - x_offs >= in_dimensions(1)) generate
                                    kernels(xx+yy*out_dimensions(0) + c*out_dimensions(1)*out_dimensions(0)+n*out_dimensions(2)*out_dimensions(1)*out_dimensions(0))(kx + ky * kernel_shape(0)) <= '1' & (data_width - 2 downto 0 => '0');
                                else generate
                                    kernels(xx+yy*out_dimensions(0) + c*out_dimensions(1)*out_dimensions(0)+n*out_dimensions(2)*out_dimensions(1)*out_dimensions(0))(kx + ky * kernel_shape(0)) <= x(xx*strides(0) + kx - x_offs + (yy*strides(1) + ky - y_offs)*in_dimensions(0) + c*in_dimensions(1)*in_dimensions(0)+n*in_dimensions(2)*in_dimensions(1)*in_dimensions(0));
                                end generate;
                            end generate;
                        end generate;
                        max : entity work.max
                        generic map (
                            data_width => data_width,
                            num_inputs => kernel_shape(0) * kernel_shape(1)
                        )
                        port map (
                            a => kernels(xx+yy*out_dimensions(0) + c*out_dimensions(1)*out_dimensions(0)+n*out_dimensions(2)*out_dimensions(1)*out_dimensions(0)),
                            c => y(xx+yy*out_dimensions(0) + c*out_dimensions(1)*out_dimensions(0)+n*out_dimensions(2)*out_dimensions(1)*out_dimensions(0))
                        );
                    end generate;
                end generate;
            end generate;
        end generate;
    end generate;

end Behavioral;
