library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.types.all;
use work.defs.all;

entity memory_fsm is
    generic (
        MEMORY_ADDR_SIZE : integer := 16;
        nn_num_in : integer;
        nn_num_out : integer;
        data_width : integer
    );
    Port ( 
        clk         : in std_logic;
        reset       : in std_logic;
        nn_input    : out array_type(nn_num_in - 1 downto 0)(data_width - 1 downto 0);
        nn_output   : in array_type(nn_num_out - 1 downto 0)(data_width - 1 downto 0);
        valid_in    : in std_logic;
        valid_out   : out std_logic;
        led         : out std_logic;
        start_in    : in std_logic;
        to_mem      : out std_logic_vector(2 * data_width - 1 downto 0);
        from_mem    : in std_logic_vector(2 * data_width - 1 downto 0);
        mem_en      : out std_logic;
        mem_we      : out std_logic;
        mem_addr    : out std_logic_vector(MEMORY_ADDR_SIZE-1 downto 0);
        
        --testing
        curr_inst : out unsigned(INSTRUCTIONS'range)
    );
end memory_fsm;

architecture Behavioral of memory_fsm is
    constant STACK_START : std_logic_vector(MEMORY_ADDR_SIZE - 1 downto 0) := std_logic_vector(TO_UNSIGNED(INPUT_SIZE, MEMORY_ADDR_SIZE) + 1);
    constant MAX_INST : unsigned(INSTRUCTIONS'range) := TO_UNSIGNED(INSTRUCTIONS'length, INSTRUCTIONS'length);

    type state_type is (START, INPUT_READ, INPUT_SEND, WAIT_DONE, RECIEVE, WRITE, STACK_READ, STACK_SEND, DONE);
    signal state, next_state : state_type;
    signal i, next_i : unsigned(MEMORY_ADDR_SIZE-1 downto 0);
    signal rec_data : std_logic_vector(2 * data_width - 1 downto 0);
    signal inst : std_logic_vector(2 downto 0);
    signal addr_diff : std_logic_vector(MEMORY_ADDR_SIZE - 1 downto 0);
    signal next_inst_count, inst_count : unsigned(INSTRUCTIONS'range) := TO_UNSIGNED(0, INSTRUCTIONS'length);
    signal next_stack_ptr, stack_ptr : std_logic_vector(MEMORY_ADDR_SIZE - 1 downto 0) := STACK_START;
    signal stack_target : std_logic_vector(MEMORY_ADDR_SIZE - 1 downto 0);
    
    signal next_to_nn, to_nn : array_type(nn_num_in - 1 downto 0)(data_width - 1 downto 0);

begin

    process(all)
    begin
        led <= '0';
        next_i <= TO_UNSIGNED(0, MEMORY_ADDR_SIZE);
        next_to_nn <= to_nn;
    
        case state is
            when START =>
                valid_out <= '0';
                mem_en <= '0';
                mem_we <= '0';
                next_inst_count <= TO_UNSIGNED(0,INSTRUCTIONS'length);
                nn_input <= (others => (others => '0'));
                next_i <= TO_UNSIGNED(0, MEMORY_ADDR_SIZE);
                if start_in = '1' then
                    next_state <= INPUT_READ;
                    led <= '0';
                else
                    next_state <= START;
                end if;
                
            when INPUT_READ => 
                valid_out <= '0';
                next_i <= i;
                mem_addr <= std_logic_vector(i);
                mem_en <= '1';
                next_state <= INPUT_SEND;
                
            when INPUT_SEND =>
                valid_out <= '0';
                mem_en <= '0';
                next_to_nn(TO_INTEGER(i)) <= signed(from_mem(data_width - 1 downto 0));
                next_to_nn(TO_INTEGER(i +1)) <= signed(from_mem(data_width * 2 - 1 downto data_width));
                next_i <= i + 2;
                if (i = TO_UNSIGNED(nn_num_in - 2, i'length)) and (not (inst = 4)) then
                    next_state <= WAIT_DONE;
                    next_inst_count <= inst_count + 1;
                elsif (i = TO_UNSIGNED(nn_num_in - 2, i'length)) and (inst = 4) then
                    next_state <= STACK_READ;
                    stack_target <= stack_ptr - addr_diff;
                else
                    next_state <= INPUT_READ;
                end if;
                
            when WAIT_DONE => 
                valid_out <= '1';
                if inst_count = MAX_INST then
                    next_state <= DONE;
                else
                    inst <= INSTRUCTIONS(TO_INTEGER(next_inst_count))(INST_SIZE - 1 downto 0);
                    addr_diff <= INSTRUCTIONS(TO_INTEGER(next_inst_count))(18 downto INST_SIZE);
                    next_i <= (others => '0');
                    if (valid_in = '1') and ((inst = 0) or (inst = 4)) and (not (inst_count = MAX_INST)) then
                        next_state <= INPUT_READ;
                    elsif (valid_in = '1') and (inst = 1) and (not (inst_count = MAX_INST)) then
                        next_state <= STACK_READ;
                        stack_target <= stack_ptr - addr_diff;
                    elsif (valid_in = '1') and ((inst = 2) or (inst = 3)) and (not (inst_count = MAX_INST)) then
                        next_state <= RECIEVE;
                        stack_target <= stack_ptr + addr_diff;
                    else 
                        next_state <= WAIT_DONE;
                    end if;
                end if;
                
            when RECIEVE => 
                valid_out <= '0';
                next_i <= i;
                mem_en <= '0';
                mem_we <= '0';
                rec_data <= std_logic_vector(nn_output(TO_INTEGER(nn_num_out - (i + 1) - 1))) & std_logic_vector(nn_output(TO_INTEGER(nn_num_out - i  - 1)));
                next_state <= WRITE;
            
            when WRITE =>
                valid_out <= '0';
                mem_en <= '1';
                mem_we <= '1';
                mem_addr <= stack_ptr;
                to_mem <= rec_data;
                next_i <= i + 2;
                next_stack_ptr <= stack_ptr + 1;
                if (next_stack_ptr = stack_target) and (not(inst = 3)) then
                    next_state <= WAIT_DONE;
                    next_inst_count <= inst_count + 1;
                elsif (next_stack_ptr = stack_target) and (inst = 3) then
                    next_state <= INPUT_READ;
                else
                    next_state <= RECIEVE;
                end if;
               
            when STACK_READ =>
                valid_out <= '0';
                next_i <= i; 
                mem_en <= '1';
                mem_addr <= stack_ptr - 1;
                next_state <= STACK_SEND;
                
            when STACK_SEND =>
                valid_out <= '0';
                mem_en <= '0';
                next_stack_ptr <= stack_ptr - 1;
                next_i <= i + 2;
                
                next_to_nn(TO_INTEGER(i)) <= signed(from_mem(data_width - 1 downto 0));
                next_to_nn(TO_INTEGER(i + 1)) <= signed(from_mem(data_width * 2 - 1 downto data_width));
                if inst = 4 then 
                    next_to_nn(TO_INTEGER(i) + integer(ceil(real(INPUT_SIZE) / real(2)))) <= signed(from_mem(data_width - 1 downto 0));
                    next_to_nn(TO_INTEGER(i + 1) + integer(ceil(real(INPUT_SIZE) / real(2)))) <= signed(from_mem(data_width * 2 - 1 downto data_width));
                end if;
                
                if next_stack_ptr = stack_target then
                    next_state <= WAIT_DONE;
                    next_inst_count <= inst_count + 1;
                else
                    next_state <= STACK_READ;
                end if;
            
            when DONE =>
                valid_out <= '0';
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
                state <= INPUT_READ;
                i <= TO_UNSIGNED(0, MEMORY_ADDR_SIZE);
                stack_ptr <= STACK_START;
                inst_count <= TO_UNSIGNED(0, INSTRUCTIONS'length);
                to_nn <= (others => (others => '0'));
            else 
                state <= next_state;
                i <= next_i;
                stack_ptr <= next_stack_ptr;
                inst_count <= next_inst_count;
                to_nn <= next_to_nn;
            end if;
        end if;
    end process;
    
    nn_input <= to_nn;
    
end Behavioral;
