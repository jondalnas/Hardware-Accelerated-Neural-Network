library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.types.all;
use work.defs.all;

entity top is
    port(
        clk_100mhz : in  std_logic;
        rst        : in  std_logic;
        led        : out std_logic;
        start      : in  std_logic;
        -- Serial interface for PC communication
        serial_tx  : in  STD_LOGIC;     -- from the PC
        serial_rx  : out STD_LOGIC      -- to the PC
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
    
    signal data_to_nn, data_from_mem : array_type(NN_INPUT - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    signal data_from_nn, data_to_mem : array_type(NN_OUTPUT - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    
begin
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
            num_in => NN_INPUT,
            num_out => NN_OUTPUT,
			num_feedback => NN_FEEDBACK,
            data_width => DATA_WIDTH
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
            nn_num_in => NN_INPUT,
            nn_num_out => NN_OUTPUT,
            data_width => DATA_WIDTH
        )
        port map (
            clk => clk,
            reset => rst,
            nn_input => data_from_mem,
            nn_output => data_to_mem,
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
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst then
				data_to_nn <= (others => (others => '0'));
				data_to_mem <= (others => (others => '0'));
			else
				data_to_nn <= data_from_mem;
				data_to_mem <= data_from_nn;
			end if;
		end if;
	end process;

end Behavioral;
