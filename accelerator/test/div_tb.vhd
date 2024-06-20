library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;


use work.types.all;
use work.defs.all;

entity div_tb is
end div_tb;

architecture div_test of div_tb is

    signal a, b, c : array_type(5 downto 0)(DATA_WIDTH - 1 downto 0);
    

begin

    div : entity work.div
        generic map(
            input_size => 6,
            data_width => DATA_WIDTH
        )
        port map (
            a => a,
            b => b,
            c => c
        );
        
        
    process
    
        variable seed1, seed2 : integer := 999;
        
        impure function rand_slv(len : integer) return std_logic_vector is
            variable r : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
                uniform(seed1, seed2, r);
                if r > 0.5 then 
                    slv(i) := '1';
                else
                    slv(i) := '0';
                end if;
            end loop;
            return slv;
        end function;
    begin
        for i in 0 to 5 loop
            a(i) <= signed(rand_slv(DATA_WIDTH));
            b(i) <= signed(rand_slv(DATA_WIDTH));
        end loop;
        
        wait for 200 ns;
    end process;
end div_test;
