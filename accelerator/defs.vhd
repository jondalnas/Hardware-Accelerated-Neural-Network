----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.06.2024 16:02:07
-- Design Name: 
-- Module Name: Defs - 
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

package defs is
    constant MAX_STACK : Integer := 256;
    constant INSTRUCTIONS : array_type(4 downto 0)(18 downto 0) := ("0000000000000010001", "0000000000000010010", "0000000000000010001", "0000000000000010010", "0000000000000010000");
    constant INPUT_SIZE : Integer := 4;
    constant INST_SIZE : Integer := 3;

end defs;