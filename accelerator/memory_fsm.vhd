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

    type state_type is (START, READ, SEND, WAIT_DONE, RECIEVE, WRITE, DONE);
    signal state, next_state : state_type;
    signal i, next_i : unsigned(maximum(nn_num_in, nn_num_out)-1 downto 0);
    signal rec_data : std_logic_vector(data_width - 1 downto 0);

begin

    process(state, start_in, i, from_mem, valid_in, nn_output, rec_data)
    begin
        led <= '0';
        next_i <= TO_UNSIGNED(0, nn_num_in);
        valid_out <= '0';
    
        case state is
            when START =>
                nn_input <= (others => (others => '0'));
                next_i <= TO_UNSIGNED(0, nn_num_in);
                if start_in = '1' then
                    next_state <= READ;
                    led <= '0';
                else
                    next_state <= START;
                end if;
                
            when READ => 
                next_i <= i;
                mem_addr <= std_logic_vector(i + TO_UNSIGNED(memory_read_start, MEMORY_ADDR_SIZE));
                mem_en <= '1';
                next_state <= SEND;
                
            when SEND =>
                mem_en <= '0';
                nn_input(TO_INTEGER(i)) <= from_mem;
                next_i <= i + 1;
                if i = TO_UNSIGNED(nn_num_in - 1, i'length) then
                    next_state <= WAIT_DONE;
                    valid_out <= '1';
                else
                    next_state <= READ;
                end if;
                
            when WAIT_DONE => 
                valid_out <= '1';
                if valid_in = '1' then
                    next_state <= RECIEVE;
                else 
                    next_state <= WAIT_DONE;
                end if;
                
            when RECIEVE => 
                led <= '1';
                next_i <= i;
                rec_data <= nn_output(TO_INTEGER(i));
                next_state <= WRITE;
            
            when WRITE =>
                mem_en <= '1';
                mem_we <= '1';
                led <= '1';
                mem_addr <= std_logic_vector(i + TO_UNSIGNED(memory_write_start, MEMORY_ADDR_SIZE));
                to_mem <= rec_data;
                next_i <= i + 1;
                if i = TO_UNSIGNED(memory_write_end - memory_write_start - 1, i'length) then
                    next_state <= DONE;
                else
                    next_state <= RECIEVE;
                end if;
            when DONE =>
                led <= '1';
                if start_in = '0' then
                    next_state <= START;
                else
                    next_state <= DONE;
                end if;
        end case;
    end process;
    
    process(clk, reset)
    begin 
        if rising_edge(clk) then
            if reset = '1' then
                state <= START;
                i <= TO_UNSIGNED(0, nn_num_in);
            else 
                state <= next_state;
                i <= next_i;
            end if;
        end if;
    end process;
    
end Behavioral;
