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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory_fsm is
    generic (
        MEMORY_ADDR_SIZE : integer := 16;
        nn_num_in : positive;
        nn_num_out : positive;
        data_width : integer;
        memory_read_start : integer;
        memory_read_end : integer;
        memory_write_start : integer;
        memory_write_end : integer
    );
    Port ( 
        clk         : in std_logic;
        reset       : in std_logic;
        nn_input    : out array_type(nn_num_in - 1 downto 0);
        nn_output   : in array_type(nn_num_out - 1 downto 0);
        valid_in    : in std_logic;
        valid_out   : out std_logic;
        led         : out std_logic;
        start_in    : in std_logic;
        to_mem      : out std_logic_vector(data_width - 1 downto 0);
        from_mem    : in std_logic_vector(data_width - 1 downto 0);
        mem_en      : out std_logic;
        mem_we      : out std_logic;
        mem_addr    : out std_logic_vector(MEMORY_ADDR_SIZE-1 downto 0)
    );
end memory_fsm;

architecture Behavioral of memory_fsm is

    type state_type is (START, READ, SEND, WAIT_DONE, RECIEVE, WRITE);
    signal state, next_state : state_type;
    signal i, next_i, j, next_j : integer;

begin

    process(state)
    begin
    
        case state is
            when START => 
                if start_in = '1' then
                    next_state <= READ;
                else
                    next_state <= START;
                end if;
                
            when READ => 
                next_state <= Send;
                
            when SEND =>
                if i = nn_num_in - 1 then
                    next_state <= WAIT_DONE;
                else
                    next_state <= READ;
                    next_i <= i + 1;
                end if;
                
            when WAIT_DONE => 
                if valid_in = '1' then
                    next_state <= RECIEVE;
                else 
                    next_state <= WAIT_DONE;
                end if;
                
            when RECIEVE => 
                next_state <= WRITE;
            
            when WRITE =>
                next_state <= START;
        end case;
    end process;
    
    process(clk, reset)
    begin 
        if rising_edge(clk) then
            if reset = '1' then
                state <= START;
                i <= 0;
                j <= 0;
            else 
                state <= next_state;
                i <= next_i;
                j <= next_j;
            end if;
        end if;
    end process;
    
end Behavioral;
