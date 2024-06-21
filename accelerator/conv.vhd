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
	type res_array is array(y_size - 1 downto 0) of array_type(kernel_size - 1 downto 0)(data_width - 1 downto 0);
	signal res : res_array;

	constant x_offs : integer := integer(ceil(real(kernel_shape(0) * dilation(0) - (dilation(0) - 1)) / 2)) - 1;
	constant y_offs : integer := integer(ceil(real(kernel_shape(1) * dilation(1) - (dilation(1) - 1)) / 2)) - 1;
	
	type state_type is (START, DONE, SUM, MULT);
    signal state, next_state : state_type;
    
    signal mult_a : res_array;
    signal mult_b : res_array;
    signal mult_in_a : signed(data_width - 1 downto 0);
    signal mult_in_b : signed(data_width - 1 downto 0);
    signal mult_out : signed(data_width - 1 downto 0);
    signal sum_in : array_type(kernel_size - 1 downto 0)(data_width - 1 downto 0);
    signal sum_out : signed(data_width - 1 downto 0);
    
    signal next_out_array, out_array : array_type(y_size - 1 downto 0)(data_width - 1 downto 0);
    
    signal next_index, index : integer;
    signal next_index_sum, index_sum : integer;
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
									mult_a(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))(xxk + yyk * kernel_shape(0)) <= (others => '0');
									mult_b(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))(xxk + yyk * kernel_shape(0)) <= (others => '0');
								else generate
								    mult_a(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= x((xx * stride(0) + xxk * dilation(0) - x_offs) + (yy * stride(1) + yyk * dilation(1) - y_offs) * dimensions_x(0) + cc * dimensions_x(0) * dimensions_x(1));
								    mult_b(xx + yy * dimensions_x(0) + llk * dimensions_x(0) * dimensions_x(1))(xxk + yyk * kernel_shape(0) + cc * kernel_shape(0) * kernel_shape(1)) <= w(xxk + yyk * dimensions_w(0) + cc * dimensions_w(0) * dimensions_w(1) + llk * dimensions_w(0) * dimensions_w(1) * dimensions_w(2));
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
        sum_in <= (others => (others => '0'));
        mult_in_a <= (others => '0');
        mult_in_b <= (others => '0');
        next_index <= 0;
        next_index_sum <= 0;
        next_state <= state;
        
        case state is
            when START =>
                next_index <= 0;
                next_index_sum <= 0;
                valid_out <= '0';
                if valid_in then
                    next_state <= MULT;
                else 
                    next_state <= START;
                end if;
            
            when MULT => 
                next_index <= index + 1;
                next_index_sum <= index_sum;
                mult_in_a <= mult_a(index_sum)(index);
                mult_in_b <= mult_b(index_sum)(index);
                res(index_sum)(index) <= mult_out;
                if index = kernel_size - 1 then
                    next_state <= SUM;
                else
                    next_state <= MULT;
                end if;
            when SUM => 
                next_index_sum <= index_sum + 1;
                next_index <= 0;
                sum_in <= res(index_sum);
                next_out_array(index_sum) <= sum_out;
                if index_sum = y_size - 1 then
                    next_state <= DONE;
                else
                    next_state <= MULT;
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
                index_sum <= 0;
                out_array <= (others => (others => '0'));
            else
                state <= next_state;
                index <= next_index;
                index_sum <= next_index_sum;
                out_array <= next_out_array;
            end if;
        end if;
    end process;
    
    y <= out_array;
    
    mul : entity work.fix_mul
        generic map(
            data_width => 16
        )
        port map(
            a => mult_in_a,
            b => mult_in_b,
            res => mult_out
        );
        
    sum1 : entity work.sum
        generic map(
            data_width => data_width,
            num_inputs => kernel_size
        )
        port map(
            a => sum_in,
            c => sum_out
        );
    
end Behavioral;
