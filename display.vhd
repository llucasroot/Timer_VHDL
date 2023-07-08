library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity disp_ss is
    Port ( numero : in std_logic_vector(3 downto 0);
           saida : out  STD_LOGIC_VECTOR (6 downto 0));
end disp_ss;

architecture Behavioral of disp_ss is
begin
with numero select
saida <=  "0000001" when x"0",
			 "1001111" when x"1",
			 "0010010" when x"2",
			 "0000110" when x"3",
			 "1001100" when x"4",
			 "0100100" when x"5",
			 "0100000" when x"6",
			 "0001111" when x"7",
			 "0000000" when x"8",
			 "0000100" when x"9",
          "0000000" when others;
end Behavioral;