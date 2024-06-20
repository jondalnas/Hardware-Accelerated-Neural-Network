library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


use work.defs.all;
use work.types.all;

entity fix_div is
    generic (
        data_width : integer := 16
    );
    Port (
        dividend : in signed(data_width - 1 downto 0);
        divisor : in signed(data_width - 1 downto 0);
        res : out signed(data_width - 1 downto 0) 
     );
end fix_div;

architecture Behavioral of fix_div is
    signal x, y : signed(data_width - 1 downto 0);
    signal x_s, y_s : signed(data_width - 2 downto 0);
    signal x_neg, y_neg : std_logic := '0';
    signal div_res : signed(data_width - 2 downto 0);
    signal x_shift : array_type(data_width - 2 downto 0)(data_width - 2 downto 0);
    signal sub_res : array_type(data_width - 2 downto 0)(data_width - 1 downto 0);
    signal mux : array_type(data_width - 2 downto 0)(data_width - 2 downto 0);
begin
    x <= divisor;
    y <= dividend;
    x_neg <= x(data_width - 1);
    y_neg <= y(data_width - 1);
    x_s <= -x(data_width - 2 downto 0) when x_neg = '1' else x(data_width - 2 downto 0);
    y_s <= -y(data_width - 2 downto 0) when y_neg = '1' else y(data_width - 2 downto 0);
    
    
    shift_gen : for i in 0 to data_width - 2 generate
        int_if : if (INTEGER_WIDTH - 2 - i) >= 0 generate
            x_shift(data_width - 2 - i) <= x_s(data_width - 2 - (INTEGER_WIDTH - 2 - i) downto 0) & (-(INTEGER_WIDTH - 2 - i) - 1 downto 0 => '0');
        else generate
            x_shift(data_width - 2 - i) <= (-(INTEGER_WIDTH - 2 - i) - 1 downto 0 => '0') & x_s(data_width - 2 downto i - (INTEGER_WIDTH - 2)) + x_s(i - (INTEGER_WIDTH - 2) - 1);
        end generate; 
    end generate;
    
    
    sub_res(data_width - 2) <= ('0' & y_s) - ('0' & x_shift(data_width - 2));
    
    div_res(data_width - 2) <= not sub_res(data_width - 2)(data_width - 1);
    
    mux(data_width - 2) <= y_s when sub_res(data_width - 2)(data_width - 1) else
              sub_res(data_width - 2)(data_width - 2 downto 0);
    
    div_gen : for j in (data_width - 3) downto 0 generate
        sub_res(j) <= ('0' & mux(j + 1)) - ('0' & x_shift(j));
        
        div_res(j) <= not sub_res(j)(data_width - 1);
        
        mux(j) <= mux(j + 1)(data_width - 2 downto 0) when sub_res(j)(data_width - 1) else
                  sub_res(j)(data_width - 2 downto 0);
    end generate;
    
    res <= '0' & div_res when (x_neg xor y_neg) = '0' else '1' & (-div_res);

end Behavioral;
