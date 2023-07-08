library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity debounce is
generic (max : integer := 10e6); -- 1 milh?o = 10ms em clock de 100Mhz
    Port ( clk : in  STD_LOGIC;
           botao : in  STD_LOGIC;
           result : out  STD_LOGIC);
end debounce;
architecture Behavioral of debounce is
signal botao_ant : std_logic  := '0'; 
begin
	process(clk)
	variable cont : integer range 0 to max := 0;
	begin
		if (clk'event and clk='1')
				then	
				      botao_ant <= botao ; -- salva o estado anterior do botao
				      if botao='1' and botao_ant='0' and cont = 0 -- alguem pressionou o botao
							   then cont := 1;
								     result <='1';
								else result <='0';
						end if;					 
						
						if botao='0' and botao_ant = '1' then cont:=1;
						end if;
                  if cont > 0 then
						         if cont < max then cont := cont +1;
							                    else cont := 0;
							      end if;
						end if;
		end if;  -- clk'event
	end process;
end Behavioral;
