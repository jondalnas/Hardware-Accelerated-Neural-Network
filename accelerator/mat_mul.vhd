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
	signal res, next_res : array_type(a_dim(0) - 1 downto 0)(data_width - 1 downto 0);
	
    type state_type is (START, DONE, SUM, MULT);
    signal state, next_state : state_type;
    
    signal mult_in_a : signed(data_width - 1 downto 0);
    signal mult_in_b : signed(data_width - 1 downto 0);
    signal mult_out : signed(data_width - 1 downto 0);
    signal sum_in : array_type(a_dim(0) - 1 downto 0)(data_width - 1 downto 0);
    signal sum_out : signed(data_width - 1 downto 0);
    
    signal next_out_array, out_array : array_type(y_size - 1 downto 0)(data_width - 1 downto 0);
    
    signal next_index, index : integer := 0;
    signal next_index_sum, index_sum : integer := 0;
    signal next_index_x, index_x : integer := 0;
    signal next_index_y, index_y : integer := 0;
    signal next_index_ya, index_ya : integer := 0;
    signal next_index_i, index_i : integer := 0;
    signal next_index_ib, index_ib : integer := 0;
begin
	process(all)
    begin
        valid_out <= '0';
        next_out_array <= out_array;
        sum_in <= (others => (others => '0'));
        mult_in_a <= (others => '0');
        mult_in_b <= (others => '0');
        next_index <= 0;
        next_index_sum <= index_sum;
        next_index_x <= index_x;
        next_index_y <= index_y;
		next_index_ya <= index_ya;
        next_index_i <= 0;
        next_index_ib <= 0;
        next_state <= state;
		next_res <= res;
        
        case state is
            when START =>
                if valid_in then
                    next_state <= MULT;
                end if;
            
            when MULT => 
                next_index <= index + 1;
				next_index_i <= index_i + 1;
				next_index_ib <= index_ib + b_dim(0);

                next_res(index) <= mult_out;

                if index = a_dim(0) - 1 then
                    next_state <= SUM;
                    
                    next_index <= 0;
                    next_index_i <= 0;
                    next_index_ib <= 0;

                end if;

            when SUM => 
                next_state <= MULT;

                next_index_sum <= index_sum + 1;
				next_index_x <= index_x + 1;

                next_out_array(index_sum) <= sum_out;

                if index_sum = y_size - 1 then
                    next_state <= DONE;
					
					next_index_sum <= 0;
					next_index_x <= 0;
					next_index_y <= 0;
					next_index_ya <= 0;

				elsif index_x = b_dim(0) - 1 then
					next_index_x <= 0;
					next_index_y <= index_y + 1;
					next_index_ya <= index_ya + a_dim(0);

                end if;

            when DONE =>
                valid_out <= '1';

                if not valid_in then
                    next_state <= START;
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
                res <= (others => (others => '0'));
            else
                state <= next_state;
                index <= next_index;
                index_x <= next_index_x;
                index_y <= next_index_y;
                index_ya <= next_index_ya;
                index_i <= next_index_i;
                index_ib <= next_index_ib;
                index_sum <= next_index_sum;
                out_array <= next_out_array;
                res <= next_res;
            end if;
        end if;
    end process;
    
    y <= out_array;
    
    mul : entity work.fix_mul
        generic map(data_width => data_width)
        port map(
            a => a(index_i + index_ya),
            b => b(index_x + index_ib),
            res => mult_out
        );
        
    sum1 : entity work.sum
        generic map(
            data_width => data_width,
            num_inputs => a_dim(0)
        )
        port map(
            a => res,
            c => sum_out
        );
end Behavioral;
