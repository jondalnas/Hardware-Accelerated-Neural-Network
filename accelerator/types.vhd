library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package types is
    type array_type is array(integer range <>) of signed;
    type dimensions_type is array(integer range <>) of integer;
end types;
