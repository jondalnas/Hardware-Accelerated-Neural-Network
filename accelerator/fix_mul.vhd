library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.defs.all;

entity fix_mul is
    generic (
        data_width : integer
    );
    Port (
        a : in signed(data_width - 1 downto 0);
        b : in signed(data_width - 1 downto 0);
        res : out signed(data_width - 1 downto 0)
     );
end fix_mul;

architecture Behavioral of fix_mul is
	constant extended_size : integer := data_width * 2 - 1;

	signal mul : signed(extended_size downto 0);
begin
	mul <= a * b;
	res <= mul(data_width * 2 - 1 - INTEGER_WIDTH downto DECIMAL_WIDTH);
end Behavioral;
