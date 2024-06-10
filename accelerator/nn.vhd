----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.06.2024 15:05:02
-- Design Name: 
-- Module Name: memory_fsm - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity nn is
    generic(
        num_in : positive;
        num_out : positive;
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
    
--    type state_type is (START, CALC);
--    signal state, next_state : state_type;
--    signal in0, in1 : signed(data_width-1 downto 0);

begin

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_out <= '0';
                output <= (others => (others => '0'));
            else
                valid_out <= valid_in;
                output <= input;
            end if;
        end if;
    end process;

--    process(input, valid_in, state)
--    constant FOR_STEP : integer := 2;
    
--    begin
        
--        case state is
--        when START =>
--            output <= (others => (others => '0'));
--            valid_out <= '0';
--            if valid_in = '1' then
--                next_state <= CALC;
--            else
--                next_state <= START;
--            end if;
        
--        when CALC => 
--            output <= input;
--            valid_out <= '1';
--            if valid_in = '0' then
--                next_state <= START;
--            else 
--                next_state <= CALC;
--            end if; 
--        end case;
        
--    end process;
    
--    process(clk, rst)
--    begin
--        if rising_edge(clk) then
--            if rst = '1' then
--                state <= START;
--                valid_out <= '0';
--            else
--                state <= next_state;
--            end if;
--        end if;
--    end process;


end Behavioral;
