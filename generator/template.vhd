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
    signal feedback, feedback_next : array_type(num_fb-1 downto 0);
    signal was_valid, was_valid_next : std_logic;

-- STATES

-- SIGNALS
begin
-- ENTITIES

-- CONSTANTS
    process(all)
    begin
        feedback_next <= feedback;
        state_next <= state;
        valid_out <= '0';
        output <= (others => (others => '0'));

        case state is
            when 0 =>
                state_next <= 0;
                if valid_in then
                    state_next <= 1;
                end if;
-- FSM
        end case;
    end process;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                feedback <= (others => (others => '0'));
                state <= (others => '0');
                was_valid <= '0';
            else
                feedback <= feedback_next;
                state <= state_next;
                was_valid <= was_valid_next;
            end if;
        end if;
    end process;
end Behavioral;
