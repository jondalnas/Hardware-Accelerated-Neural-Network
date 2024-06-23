library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity relu is
    generic (
        input_size : integer;
        data_width : integer
    );
    Port ( 
		clk : in std_logic;
		rst : in std_logic;
		valid_in : in std_logic;
		valid_out : out std_logic;
        x : in array_type(input_size - 1 downto 0)(data_width - 1 downto 0);
        y : out array_type(input_size - 1 downto 0)(data_width - 1 downto 0)
    );
end relu;

architecture Behavioral of relu is
	type state_type is (START, DONE, CALC);
	signal state, next_state : state_type;

	signal relu_res : signed(data_width - 1 downto 0);

	signal res, next_res : array_type(input_size - 1 downto 0)(data_width - 1 downto 0);

	signal index, next_index : integer := 0;
begin
	process(all)
	begin
		valid_out <= '0';

		next_state <= state;
		next_res <= res;
		next_index <= 0;

		case state is
			when START =>
				next_state <= START;
				if valid_in then
					next_state <= CALC;
				end if;

			when CALC =>
				next_state <= CALC;
				next_index <= index + 1;

				next_res(index) <= relu_res;

				if index = input_size - 1 then
					next_state <= DONE;
				    next_index <= 0;
				end if;

			when DONE =>
				next_state <= DONE;
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
				res <= (others => (others => '0'));
				index <= 0;
			else
				state <= next_state;
				res <= next_res;
				index <= next_index;
			end if;
		end if;
	end process;

	reslu_res <= x(index) when x(index)(data_width - 1) = '0' else (others => '0');
end Behavioral;
