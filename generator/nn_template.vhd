library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;
use IEEE.NUMERIC_STD.ALL;

entity nn is
    generic(
        num_in : positive;
        num_out : positive;
        num_feedback : positive;
        data_width : integer
    );
    Port (
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic;
        input : in array_type(num_in-1 downto 0);
        output : out array_type(num_out-1 downto 0)
     );
end nn;

architecture Behavioral of nn is
    signal feedback, next_feedback : array_type(num_feedback-1 downto 0)(data_width - 1 downto 0);
    signal was_valid, next_was_valid : std_logic;

-- STATES

-- SIGNALS
begin
-- ENTITIES

-- CONSTANTS
    process(all)
    begin
        next_feedback <= feedback;
        next_state <= state;
        next_was_valid <= was_valid;
        valid_out <= '0';
        output <= (others => (others => '0'));

        case state is
            when 0 =>
                next_state <= 0;
                if valid_in then
                    next_state <= 1;
                end if;
-- FSM
        end case;
    end process;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                feedback <= (others => (others => '0'));
                state <= 0;
                was_valid <= '0';
            else
                feedback <= next_feedback;
                state <= next_state;
                was_valid <= next_was_valid;
            end if;
        end if;
    end process;
end Behavioral;
