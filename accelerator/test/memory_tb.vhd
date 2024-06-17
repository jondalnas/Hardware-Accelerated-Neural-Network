----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.06.2024 10:23:03
-- Design Name: 
-- Module Name: memory_tb - Behavioral
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

entity memory_tb is
end memory_tb;

architecture mem_test of memory_tb is

    signal clk, rst : std_logic := '0';
    signal nn_in, nn_out : array_type(3 downto 0)(15 downto 0);
    signal val_in, val_out : std_logic := '0';
    signal done, start : std_logic;
    signal to_mem, from_mem : std_logic_vector(31 downto 0);
    signal en, we : std_logic;
    signal addr : std_logic_vector(15 downto 0);
    signal to_memb, from_memb : std_logic_vector(31 downto 0) := (others => '0');
    signal enb, web : std_logic := '0';
    signal addrb : std_logic_vector(15 downto 0):= (others => '0');
    signal finished : std_logic := '0';
begin

clk <= not clk after 500 ns when finished /= '1' else '0';

dut : entity work.memory_fsm
generic map(
    nn_num_in => 4,
    nn_num_out => 4,
    data_width => 16
)
port map (
    clk => clk,
    reset => rst,
    nn_input => nn_in,
    nn_output => nn_out,
    valid_in => val_in,
    valid_out => val_out,
    led => done,
    start_in => start,
    to_mem => to_mem,
    from_mem => from_mem,
    mem_en => en,
    mem_we => we,
    mem_addr => addr
);

memory3_inst_0 : entity work.memory3
generic map(
    ADDR_SIZE => 16
)
port map(
    clk   => clk,
    -- Port a (for the accelerator)
    ena   => en,
    wea   => we,
    addra => addr,
    dia   => to_mem,
    doa   => from_mem,
    -- Port b (for the uart/controller)
    enb   => enb,
    web   => web,
    addrb => addrb,
    dib   => to_memb,
    dob   => from_memb
);

process 
    begin
        start <= '1';
        wait until val_out = '1';
        start <= '0';
        for i in nn_in'range loop
            nn_out(i) <= "0000001000000000" or std_logic_vector(TO_UNSIGNED(i, 16));
        end loop;
        val_in <= '1';
        wait until val_out = '0';
        val_in <= '0';
        wait until val_out = '1';
        val_in <= '1';
        wait until val_out = '0';
        val_in <= '0';
        wait until val_out = '1';
        for i in nn_in'range loop
            nn_out(i) <= "0010001000001010" or std_logic_vector(TO_UNSIGNED(i, 16));
        end loop;
        val_in <= '1';
        wait until val_out = '0';
        val_in <= '0';
        wait until val_out = '1';
        val_in <= '1';
        wait until val_out = '0';
        val_in <= '0';
        wait until val_out = '1';
        wait until done = '1';
        finished <= '1';
end process;




end mem_test;
