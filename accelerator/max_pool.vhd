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
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic;
        x : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(output_size - 1 downto 0)(data_width - 1 downto 0)
     );
end max_pool;

architecture FSM of max_pool is
    --TODO : add padding
    type kernel_array_type is array(0 to output_size - 1) of array_type(0 to kernel_shape(0) * kernel_shape(1) - 1)(data_width - 1 downto 0);
    signal kernels : kernel_array_type;
 
    constant x_offs : integer := integer(ceil(real(kernel_shape(0)) / 2.0)) - 1;
    constant y_offs : integer := integer(ceil(real(kernel_shape(1)) / 2.0)) - 1;

    type state_type is (START, DONE, CALC);
    signal state, next_state : state_type;
    
    signal max_in : array_type(0 to kernel_shape(0) * kernel_shape(1) - 1)(data_width - 1 downto 0);
    signal max_out : signed(data_width - 1 downto 0);
    
    signal next_out_array, out_array : array_type(output_size - 1 downto 0)(data_width - 1 downto 0);
    
    signal next_index, index : integer;

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
                    end generate;
                end generate;
            end generate;
        end generate;
    end generate;

    process(all)
    begin
        valid_out <= '0';
        next_out_array <= out_array;
        max_in <= (others => (others => '0'));
        next_index <= 0;
        next_state <= state;
        
        case state is
            when START =>
                next_index <= 0;
                valid_out <= '0';
                if valid_in then
                    next_state <= CALC;
                else 
                    next_state <= START;
                end if;
            
            when CALC => 
                next_index <= index + 1;
                max_in <= kernels(index);
                next_out_array(index) <= max_out;
                if index = output_size - 1 then
                    next_state <= DONE;
                else
                    next_state <= CALC;
                end if;
            when DONE =>
                next_index <= 0;
                valid_out <= '1';
                if not valid_in then
                    next_state <= START;
                else
                    next_state <= DONE;
                end if;
        end case;
    
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst then
                state <= START;
                index <= 0;
                out_array <= (others => (others => '0'));
            else
                state <= next_state;
                index <= next_index;
                out_array <= next_out_array;
            end if;
        end if;
    end process;
    
    
    y <= out_array;

    max : entity work.max
        generic map(
            data_width => data_width,
            num_inputs => kernel_shape(0) * kernel_shape(1)
        )
        port map(
            a => max_in,
            c => max_out
        );

end FSM;
