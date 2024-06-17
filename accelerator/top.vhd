----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.06.2024 14:20:52
-- Design Name: 
-- Module Name: top - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    port(
        clk_100mhz : in  std_logic;
        rst        : in  std_logic;
        led        : out std_logic;
        start      : in  std_logic;
        -- Serial interface for PC communication
        serial_tx  : in  STD_LOGIC;     -- from the PC
        serial_rx  : out STD_LOGIC;      -- to the PC
        -- Testing ports
        led1 : out std_logic;
        led2 : out std_logic;
        led3 : out std_logic;
        led4 : out std_logic;
        led5 : out std_logic;
        led6 : out std_logic;
        led7 : out std_logic;
        led8 : out std_logic;
        txled : out std_logic
    );
end top;

architecture Behavioral of top is

    constant CLK_DIVISION_FACTOR : integer := 2; --(1 to 7)
    signal clk   : std_logic;

    signal addr     : std_logic_vector(15 downto 0);
    signal dataR    : std_logic_vector(31 downto 0);
    signal dataW    : std_logic_vector(31 downto 0);
    signal en       : std_logic;
    signal we       : std_logic;
    signal finish   : std_logic;
    signal start_db : std_logic;

    signal mem_enb   : std_logic;
    signal mem_web   : std_logic;
    signal mem_addrb : std_logic_vector(15 downto 0);
    signal mem_dib   : std_logic_vector(31 downto 0);
    signal mem_dob   : std_logic_vector(31 downto 0);

    signal data_stream_in      : std_logic_vector(7 downto 0);
    signal data_stream_in_stb  : std_logic;
    signal data_stream_in_ack  : std_logic;
    signal data_stream_out     : std_logic_vector(7 downto 0);
    signal data_stream_out_stb : std_logic;
    
    signal valid_to_nn, valid_from_nn : std_logic;
    
    signal data_to_nn : array_type(7 downto 0)(15 downto 0);
    signal data_from_nn : array_type(7 downto 0)(15 downto 0);
    
    --Testing signals
    type bit_vec is array(7 downto 0) of std_logic;
    signal correct : bit_vec := (others => '0');
    
begin
    
    --Testing process
    test : process (data_to_nn, data_from_nn)
    begin
        for i in 0 to 7 loop
            if data_to_nn(i) = data_from_nn(i) then
                correct(i) <= '1';
            end if;
        end loop;
    end process;
    
    -- Testing    
    led1 <= data_stream_out(0);
    led2 <= data_stream_out(1);
    led3 <= data_stream_out(2);
    led4 <= data_stream_out(3);
    led5 <= data_stream_out(4);
    led6 <= data_stream_out(5);
    led7 <= data_stream_out(6);
    led8 <= data_stream_out(7);
    txled <= serial_tx;
    
    clock_divider_inst_0 : entity work.clock_divider
        generic map(
            DIVIDE => CLK_DIVISION_FACTOR
        )
        port map(
            clk_in  => clk_100mhz,
            clk_out => clk
        );
    
    controller_inst_0 : entity work.controller
        generic map(
            MEMORY_ADDR_SIZE => 16
        )
        port map(
            clk                => clk,
            reset              => rst,
            data_stream_tx     => data_stream_in,
            data_stream_tx_stb => data_stream_in_stb,
            data_stream_tx_ack => data_stream_in_ack,
            data_stream_rx     => data_stream_out,
            data_stream_rx_stb => data_stream_out_stb,
            mem_en             => mem_enb,
            mem_we             => mem_web,
            mem_addr           => mem_addrb,
            mem_dw             => mem_dib,
            mem_dr             => mem_dob
        );
        
        uart_inst_0 : entity work.uart
        generic map(
            baud            => 9600,
            clock_frequency => positive(100_000_000 / 2)
        )
        port map(
            clock               => clk,
            reset               => rst,
            data_stream_in      => data_stream_in,
            data_stream_in_stb  => data_stream_in_stb,
            data_stream_in_ack  => data_stream_in_ack,
            data_stream_out     => data_stream_out,
            data_stream_out_stb => data_stream_out_stb,
            tx                  => serial_rx,
            rx                  => serial_tx
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
            dia   => dataW,
            doa   => dataR,
            -- Port b (for the uart/controller)
            enb   => mem_enb,
            web   => mem_web,
            addrb => mem_addrb,
            dib   => mem_dib,
            dob   => mem_dob
        );
        
        nerual_net_inst : entity work.nn
        generic map (
            num_in => 8,
            num_out => 8,
            data_width => 16
        )
        port map (
            clk => clk,
            rst => rst,
            valid_in => valid_to_nn,
            valid_out => valid_from_nn,
            input => data_to_nn,
            output => data_from_nn
        );
        
        memory_fsm_inst : entity work.memory_fsm
        generic map (
            nn_num_in => 8,
            nn_num_out => 8,
            data_width => 16
        )
        
        port map (
            clk => clk,
            reset => rst,
            nn_input => data_to_nn,
            nn_output => data_from_nn,
            valid_in => valid_from_nn,
            valid_out => valid_to_nn,
            led => led,
            start_in => start,
            to_mem => dataW,
            from_mem => dataR,
            mem_en => en,
            mem_we => we,
            mem_addr => addr
        );

end Behavioral;
