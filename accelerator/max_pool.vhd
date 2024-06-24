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
    signal kernels : array_type(0 to kernel_shape(0) * kernel_shape(1) - 1)(data_width - 1 downto 0);
 
    constant x_offs : integer := integer(ceil(real(kernel_shape(0)) / 2.0)) - 1;
    constant y_offs : integer := integer(ceil(real(kernel_shape(1)) / 2.0)) - 1;

    constant MIN_VALUE : signed(data_width - 1 downto 0) := '1' & (data_width - 2 downto 0 => '0');

    type state_type is (START, DONE, CALC);
    signal state, next_state : state_type;
    
    signal max_in : array_type(0 to kernel_shape(0) * kernel_shape(1) - 1)(data_width - 1 downto 0);
    signal max_out : signed(data_width - 1 downto 0);
    
    signal next_out_array, out_array : array_type(output_size - 1 downto 0)(data_width - 1 downto 0);
    
    signal next_index, index : integer := 0;
    signal next_index_xx, index_xx : integer := 0;
    signal next_index_xx_strides, index_xx_strides : integer := 0;
    signal next_index_yy_strides, index_yy_strides : integer := 0;
    signal next_index_color_layer, index_color_layer : integer := 0;

begin

    im_gen : if num_dimensions = 4 generate -- Generate hardware for the specific 4 dimension case
        kern_y_gen : for ky in 0 to kernel_shape(1) - 1 generate
            kern_x_gen : for kx in 0 to kernel_shape(0) - 1 generate
                oob : if (kx - x_offs < 0) and (ky - y_offs < 0) generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + kx - x_offs + (ky - y_offs) * in_dimensions(0) + index_color_layer) when (index_xx_strides + kx - x_offs >= 0) and (index_yy_strides + (ky - y_offs) * in_dimensions(0) >= 0) else MIN_VALUE;

                elsif (kx - x_offs > 0) and (ky - y_offs < 0) generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + kx - x_offs + (ky - y_offs) * in_dimensions(0) + index_color_layer) when (index_xx_strides + kx - x_offs < in_dimensions(0)) and (index_yy_strides + (ky - y_offs) * in_dimensions(0) >= 0) else MIN_VALUE;

                elsif (kx - x_offs < 0) and (ky - y_offs > 0) generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + kx - x_offs + (ky - y_offs) * in_dimensions(0) + index_color_layer) when (index_xx_strides + kx - x_offs >= 0) and (index_yy_strides + (ky - y_offs) * in_dimensions(0) < in_dimensions(1) * in_dimensions(0)) else MIN_VALUE;

                elsif (kx - x_offs > 0) and (ky - y_offs > 0) generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + kx - x_offs + (ky - y_offs) * in_dimensions(0) + index_color_layer) when (index_xx_strides + kx - x_offs < in_dimensions(0)) and (index_yy_strides + (ky - y_offs) * in_dimensions(0) < in_dimensions(1) * in_dimensions(0)) else MIN_VALUE;

                elsif kx - x_offs < 0 generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + kx - x_offs + index_color_layer) when (index_xx_strides + kx - x_offs >= 0) else MIN_VALUE;

                elsif kx - x_offs > 0 generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + kx - x_offs + index_color_layer) when (index_xx_strides + kx - x_offs < in_dimensions(0)) else MIN_VALUE;

                elsif ky - y_offs < 0 generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + (ky - y_offs) * in_dimensions(0) + index_color_layer) when (index_yy_strides + (ky - y_offs) * in_dimensions(0) >= 0) else MIN_VALUE;

                elsif ky - y_offs > 0 generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + (ky - y_offs) * in_dimensions(0) + index_color_layer) when (index_yy_strides + (ky - y_offs) * in_dimensions(0) < in_dimensions(1) * in_dimensions(0)) else MIN_VALUE;

                else generate
                    kernels(kx + ky * kernel_shape(0)) <= x(index_xx_strides + index_yy_strides + index_color_layer);

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
        next_index_xx <= index_xx;
        next_index_xx_strides <= index_xx_strides;
        next_index_yy_strides <= index_yy_strides;
        next_index_color_layer <= index_color_layer;
        
        case state is
            when START =>
                if valid_in then
                    next_state <= CALC;
                else 
                    next_state <= START;
                end if;
            
            when CALC => 
                next_index <= index + 1;
                next_index_xx <= index_xx + 1;
                next_index_xx_strides <= index_xx_strides + strides(0);

                next_out_array(index) <= max_out;

                if index = output_size - 1 then
                    next_state <= DONE;
                    next_index <= 0;
                    next_index_xx <= 0;
                    next_index_xx_strides <= 0;
                    next_index_yy_strides <= 0;

                elsif index_xx = in_dimensions(0) - 2 then
                    next_index_xx <= 0;
                    next_index_xx_strides <= 0;
                    next_index_yy_strides <= index_yy_strides + strides(1) * in_dimensions(0);

                end if;

            when DONE =>
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
                index_xx <= 0;
                index_xx_strides <= 0;
                index_yy_strides <= 0;
                index_color_layer <= 0;
                out_array <= (others => (others => '0'));
            else
                state <= next_state;
                index <= next_index;
                index_xx <= next_index_xx;
                index_xx_strides <= next_index_xx_strides;
                index_yy_strides <= next_index_yy_strides;
                index_color_layer <= next_index_color_layer;
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
            a => kernels,
            c => max_out
        );

end FSM;
