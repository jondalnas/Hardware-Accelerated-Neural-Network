library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
	
    type state_type is (START, DONE, SUM, MULT);
    signal state, next_state : state_type;
    
    signal mult_a : res_array;
    signal mult_b : res_array;
    signal mult_in_a : signed(data_width - 1 downto 0);
    signal mult_in_b : signed(data_width - 1 downto 0);
    signal mult_out : signed(data_width - 1 downto 0);
    signal sum_in : array_type(a_dim(0) - 1 downto 0)(data_width - 1 downto 0);
    signal sum_out : signed(data_width - 1 downto 0);
    
    signal next_out_array, out_array : array_type(y_size - 1 downto 0)(data_width - 1 downto 0);
    
    signal next_index, index : integer;
    signal next_index_sum, index_sum : integer;
begin
	dim2 : if num_dimensions = 2 generate
		yl : for yy in 0 to a_dim(1) - 1 generate
			xl : for xx in 0 to b_dim(0) - 1 generate
				il : for i in 0 to a_dim(0) - 1 generate
				    mult_a(xx+yy*b_dim(0))(i) <= a(i + yy * a_dim(0));
				    mult_b(xx+yy*b_dim(0))(i) <= b(xx + i * b_dim(0));
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
                if index = a_dim(0) - 1 then
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
        generic map(data_width => data_width)
        port map(
            a => mult_in_a,
            b => mult_in_b,
            res => mult_out
        );
        
    sum1 : entity work.sum
        generic map(
            data_width => data_width,
            num_inputs => a_dim(0)
        )
        port map(
            a => sum_in,
            c => sum_out
        );
end Behavioral;
