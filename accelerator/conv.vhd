library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

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
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic;
        x : in array_type(x_size - 1 downto 0)(data_width - 1 downto 0);
        w : in array_type(w_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(y_size - 1 downto 0)(data_width - 1 downto 0)
     );
end conv;

architecture Behavioral of conv is
	signal res, next_res : array_type(kernel_size * dimensions_x(num_dimensions - 2) - 1 downto 0)(data_width - 1 downto 0);

	constant x_offs : integer := integer(ceil(real(kernel_shape(0) * dilation(0) - (dilation(0) - 1)) / 2)) - 1;
	constant y_offs : integer := integer(ceil(real(kernel_shape(1) * dilation(1) - (dilation(1) - 1)) / 2)) - 1;
	
	type state_type is (START, DONE, SUM, MULT);
    signal state, next_state : state_type;
    
    signal mult_a : array_type(kernel_size * dimensions_x(num_dimensions - 2) - 1 downto 0)(data_width - 1 downto 0);
    signal mult_out : signed(data_width - 1 downto 0);
    signal sum_out : signed(data_width - 1 downto 0);
    
    signal next_out_array, out_array : array_type(y_size - 1 downto 0)(data_width - 1 downto 0);
    
    signal next_index_mult, index_mult : integer := 0;
    signal next_index_sum, index_sum : integer := 0;
    signal next_index_xx, index_xx : integer := 0;
    signal next_index_yy, index_yy : integer := 0;
    signal next_index_xx_strided, index_xx_strided : integer := 0;
    signal next_index_yy_strided, index_yy_strided : integer := 0;
    signal next_index_out_layer, index_out_layer : integer := 0;
    signal next_index_w_layer, index_w_layer : integer := 0;

	signal x_edge, y_edge, layer_edge : boolean;
begin
	dim2 : if num_dimensions = 4 generate
		--Assuming no layers to input image, might be wrong

		-- Color channel loop
		cl : for cc in 0 to dimensions_x(2) - 1 generate
			-- Kernel loop
			yk : for yyk in 0 to kernel_shape(1) - 1 generate
				xk : for xxk in 0 to kernel_shape(0) - 1 generate
					-- If OOB, set element to 0
					oob : if (xxk * dilation(0) - x_offs < 0) and (yyk * dilation(1) - y_offs < 0) generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (xxk * dilation(0) - x_offs) + (yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)) when (index_xx_strided + xxk * dilation(1) - x_offs >= 0             ) and (index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) * stride(1) >= 0             ) else (others => '0');

					elsif (xxk * dilation(0) - x_offs > 0) and (yyk * dilation(1) - y_offs < 0) generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (xxk * dilation(0) - x_offs) + (yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)) when (index_xx_strided + xxk * dilation(1) - x_offs < dimensions_x(0)) and (index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) * stride(1) >= 0             ) else (others => '0');

					elsif (xxk * dilation(0) - x_offs < 0) and (yyk * dilation(1) - y_offs > 0) generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (xxk * dilation(0) - x_offs) + (yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)) when (index_xx_strided + xxk * dilation(1) - x_offs >= 0             ) and (index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) * stride(1) < dimensions_x(1) * dimensions_x(0) * stride(1)) else (others => '0');

					elsif (xxk * dilation(0) - x_offs > 0) and (yyk * dilation(1) - y_offs > 0) generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (xxk * dilation(0) - x_offs) + (yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)) when (index_xx_strided + xxk * dilation(1) - x_offs < dimensions_x(0)) and (index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) * stride(1) < dimensions_x(1) * dimensions_x(0) * stride(1)) else (others => '0');

					elsif xxk * dilation(1) - x_offs < 0 generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (xxk * dilation(0) - x_offs) + cc * dimensions_x(0) * dimensions_x(1)) when index_xx_strided + xxk * dilation(0) - x_offs >= 0 else (others => '0');

					elsif xxk * dilation(1) - x_offs > 0 generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (xxk * dilation(0) - x_offs) + cc * dimensions_x(0) * dimensions_x(1)) when index_xx_strided + xxk * dilation(0) - x_offs < dimensions_x(0) else (others => '0');

					elsif yyk * dilation(1) - y_offs < 0 generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)) when index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) * stride(1) >= 0 else (others => '0');

					elsif yyk * dilation(1) - y_offs > 0 generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1)) when index_yy_strided + (yyk * dilation(1) - y_offs) * dimensions_x(0) * stride(1) < dimensions_x(1) * dimensions_x(0) * stride(1) else (others => '0');

					else generate
						mult_a(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x(index_xx_strided + index_yy_strided + cc * dimensions_x(0) * dimensions_x(1));

					end generate;
				end generate;
			end generate;
		end generate;
	end generate;
	
    process(all)
    begin
        valid_out <= '0';
        next_out_array <= out_array;
        next_index_mult <= 0;
        next_index_sum <= 0;
		next_index_xx <= 0;
		next_index_yy <= 0;
		next_index_xx_strided <= 0;
		next_index_yy_strided <= 0;
        next_state <= state;
        next_res <= res;
        next_index_out_layer <= index_out_layer;
        next_index_w_layer <= index_w_layer;
        
        case state is
            when START =>
                if valid_in then
                    next_state <= MULT;
                else 
                    next_state <= START;
                end if;
            
            when MULT => 
                next_index_mult <= index_mult + 1;
                next_index_sum <= index_sum;
				next_index_xx <= index_xx;
				next_index_xx_strided <= index_xx_strided;
				next_index_yy <= index_yy;
				next_index_yy_strided <= index_yy_strided;
                next_res(index_mult) <= mult_out;
                if index_mult = kernel_size * dimensions_x(num_dimensions - 2) - 1 then
                    next_state <= SUM;
                    next_index_mult <= 0;
                else
                    next_state <= MULT;
                end if;

            when SUM => 
                next_state <= MULT;

                next_index_sum <= index_sum + 1;
				next_index_xx <= index_xx + 1;
				next_index_xx_strided <= index_xx_strided + stride(0);
				next_index_yy <= index_yy;
				next_index_yy_strided <= index_yy_strided;
                next_index_mult <= 0;
                next_out_array(index_xx + index_yy + index_out_layer) <= sum_out;
                
				if x_edge and y_edge and layer_edge then
					next_state <= DONE;
					next_index_out_layer <= 0;
					next_index_w_layer <= 0;
                    next_index_xx <= 0;
                    next_index_xx_strided <= 0;
                    next_index_yy <= 0;
                    next_index_yy_strided <= 0;

				elsif x_edge and y_edge then
                    next_index_out_layer <= index_out_layer + y_size / dimensions_w(num_dimensions - 1);
                    next_index_w_layer <= index_w_layer + w_size / dimensions_w(num_dimensions - 1);
                    next_index_xx <= 0;
                    next_index_xx_strided <= 0;
                    next_index_yy <= 0;
                    next_index_yy_strided <= 0;
                    
				elsif x_edge then
					next_index_xx <= 0;
                    next_index_xx_strided <= 0;
					next_index_yy <= index_yy + dimensions_x(0);
                    next_index_yy_strided <= index_yy_strided + dimensions_x(0) * stride(1);

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
                index_mult <= 0;
                index_sum <= 0;
				index_xx <= 0;
				index_yy <= 0;
				index_xx_strided <= 0;
				index_yy_strided <= 0;
                index_out_layer <= 0;
                index_w_layer <= 0;
                out_array <= (others => (others => '0'));
                res <= (others => (others => '0'));
            else
                state <= next_state;
                index_mult <= next_index_mult;
                index_sum <= next_index_sum;
				index_xx <= next_index_xx;
				index_yy <= next_index_yy;
				index_xx_strided <= next_index_xx_strided;
				index_yy_strided <= next_index_yy_strided;
                index_out_layer <= next_index_out_layer;
                index_w_layer <= next_index_w_layer;
                out_array <= next_out_array;
                res <= next_res;
            end if;
        end if;
    end process;

	x_edge <= index_xx = dimensions_x(0) - 1;
	y_edge <= index_yy = dimensions_x(0) * (dimensions_x(1) - 1);
	layer_edge <= index_out_layer = y_size - y_size / dimensions_w(num_dimensions - 1);
    
    y <= out_array;
    
    mul : entity work.fix_mul
        generic map(
            data_width => 16
        )
        port map(
            a => mult_a(index_mult),
            b => w(index_mult + index_w_layer),
            res => mult_out
        );
        
    sum1 : entity work.sum
        generic map(
            data_width => data_width,
            num_inputs => kernel_size * dimensions_x(2)
        )
        port map(
            a => res,
            c => sum_out
        );
    
end Behavioral;
