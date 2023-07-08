library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity timmer_top is
Port (  clk: in std_logic;
        rst: in std_logic;
        btn_up : in std_logic;
        btn_down: in std_logic;
        btn_start: in std_logic;
        seg_out : out std_logic_vector(6 downto 0);       
        disp_out : out std_logic_vector(3 downto 0));
end timmer_top;

architecture Behavioral of timmer_top is
type t_state is (
	s0,  --RESET
	s1,  --ESPERA START
	s3,  --SALVA DADOS
	s2,  --CONTANDO
	done); --DONE

--SINAIS DOS ESTADOS
signal estado, proximo_estado : t_state;

--SINAIS DOS BOTÕES COM DEBOUNCE
signal db_up : std_logic; 			 		--btn_up depois do debounce
signal s_up,s_up_ant : std_logic; 		--sinal up processado
signal db_down : std_logic; 		 		--btn_down depois do debounce
signal s_down,s_down_ant : std_logic; 	--sinal down processado
signal db_start : std_logic;			   --btn_start depois do debounce
signal s_start,s_start_ant : std_logic;--sinal start processado

--SINAIS PARA INDICAR FIM DE CONTAGEM E CONTADOR
signal fim_cont : std_logic; 				--flag para indicar final da contagem
signal s_timmer : std_logic;				--sinal que indica que passou 1 segundo(ativo 1 ciclo de clk);

--SINAIS QUE REPRESENTAM AS UNIDADES E DEZENAS DE MINUTOS/SEGUNDOS
signal seg0 : unsigned(3 downto 0);
signal seg1 : unsigned(3 downto 0);
signal min0 : unsigned(3 downto 0);
signal min1 : unsigned(3 downto 0);

signal set_seg0 : unsigned(3 downto 0);
signal set_seg1 : unsigned(3 downto 0);
signal set_min0 : unsigned(3 downto 0);
signal set_min1 : unsigned(3 downto 0);

--SINAIS DE SELEÇÃO DO DISPLAY
signal display_atual : unsigned(1 downto 0):= "00"; --estado atual
signal segmento: std_logic_vector(3 downto 0);		 --seletor do display
signal display : std_logic_vector(6 downto 0);		 --seletor do numero a ser exibido no display

begin

--DEFINIÇÃO DOS ESTADOS
process(clk,rst)
begin
	if rising_edge(clk) then
		if rst = '1' then
			estado <= s0;
		else
			estado <= proximo_estado;
		end if;
	end if;
end process;

process(s_start,estado, fim_cont)
begin 
	case estado is 
		when s0 =>
			proximo_estado <= s1;
		when s1 =>
			if s_start = '1' then
				proximo_estado <= s3;
			else 
				proximo_estado <= s1;
			end if;
	    when s3 =>
	           proximo_estado <= s2;
		when s2 =>
			if (fim_cont='1') then
				proximo_estado <= done;
			else
				proximo_estado <= s2;
			end if;
		when done =>
			proximo_estado  <= s0;
		when others =>
			proximo_estado <= s0;
	end case;
end process;

--FLAG DE FIM DA CONTAGEM
fim_cont <= '1' when (seg0 = "0000") and (seg1 = "0000") and (min0 = "0000") and (min1 = "0000") else '0';

--DEFINIÇÕES PARA DEBOUNCE DOS BOTÕES
	process(clk) --detector de eventos(faz que um evento de click do botão tenha a duração de 1 ciclo de clk)
	begin
		if rising_edge(clk) then
            s_up_ant <= db_up ; --salva o estado anterior do botao
			s_down_ant <= db_down;
			
			--DB_BTN_UP
			if db_up='1' and s_up_ant='0' then
		         s_up <= '1';
		    else
		         s_up <= '0';
		    end if;     
		    --DB_BTN_DOWN
		    if db_down='1' and s_down_ant='0' then
		         s_down <= '1';
		    else 
		         s_down <= '0';
		    end if;      
		end if;
	end process;

--DEFINIÇÃO DO TEMPO
   process(clk)
   begin
        if rising_edge(clk) then
            if estado = s0 then
                set_seg0 <= (others=>'0'); 
                set_seg1 <= (others=>'0');
                set_min0 <= (others=>'0');
                set_min1 <= (others=>'0');
            elsif estado = s1 then
				    --BOTÃO UP
                if s_up = '1' then
                    if set_seg0 = x"9" then
                        set_seg0 <= "0000";
                        if set_seg1 = x"5" then
                            set_seg1 <= "0000";
                            if set_min0 = x"9" then
                                set_min0 <= "0000";
                                if set_min1 = x"5" then
                                    set_min1 <= x"5";
                                else 
                                    set_min1 <= set_min1 + 1;
                                end if;                               
                            else
                                set_min0 <= set_min0 + 1;
                            end if;
                        else
                            set_seg1 <= set_seg1 + 1;
                        end if;
                    else
                        set_seg0 <= set_seg0 + 1;
                    end if;
                --BOTÃO DOWN
                elsif s_down = '1' then
                    if set_seg0 = x"0" and set_seg1 > 0 then
                        set_seg0 <= x"9";
                        if set_seg1 = x"0" and set_min0 > 0 then
                            set_seg1 <= x"5";
                            if set_min0 = x"0" and set_min1 > 0 then
                                set_min0 <= x"9";
                                if set_min1 = x"0" then
                                    set_min1 <= x"0";
                                else 
                                    set_min1 <= set_min1 - 1;
                                end if;                               
                            else
                                set_min0 <= set_min0 - 1;
                            end if;
                        else
                            set_seg1 <= set_seg1 - 1;
                        end if;
                    else
                        set_seg0 <= set_seg0 - 1;
                    end if;  
                end if;
            end if;
        end if; 
    end process;

--OPERAÇÃO NA CONTAGEM DO TIMER
process(clk, estado, fim_cont,s_timmer)
begin
    if rising_edge(clk) then
        if estado = s0 then
            seg0 <= (others => '0');
            seg1 <= (others => '0');
            min0 <= (others => '0');
            min1 <= (others => '0');
        elsif estado = s1 then
            seg0 <= set_seg0;
            seg1 <= set_seg1;
            min0 <= set_min0;
            min1 <= set_min1;
        elsif (estado = s2) then
             if (fim_cont = '0') and (s_timmer = '1') then
                if seg0 = 0 then
                    seg0 <= x"9";  --hexadecimal
                    if seg1 = 0 then
                        seg1 <= x"5";
                        if min0 = 0 then
                            min0 <= x"9";
                            if min1 = 0 then
                                min1 <= "0000";
                            else
                                min1 <= min1 - x"1";
                            end if;
                        else
                            min0 <= min0 - x"1";
                        end if;
                    else
                        seg1 <=seg1 - x"1";
                    end if;              
                else
                    seg0 <= seg0 - x"1";
                end if;   
             end if;
        end if;
    end if;
end process;

--CONTADOR DE 1 SEGUNDO
process(clk)
variable cont_s : natural range 0 to 100_000_000:=1;
begin
    if (rising_edge(clk)) then
        if rst = '1' then
            cont_s := 1;
        else
            if cont_s = 100_000_000 then
                cont_s := 0;
             else
                cont_s := cont_s + 1;
             end if;
        end if;
    end if;
    if cont_s = 0 then
        s_timmer <= '1';
    else 
        s_timmer <= '0';
    end if;        
end process;

--PORT MAP BOTÕES, DEBOUNCE E DISPLAY
BTN_UP_Debounce: entity work.debounce(Behavioral)
port map (
    clk => clk,
    botao => btn_up,
    result => db_up);

BTN_DOWN_Debounce: entity work.debounce(Behavioral)
port map (
    clk => clk,
    botao => btn_down,
    result => db_down);

BTN_START_Debounce: entity work.debounce(Behavioral)
port map (
    clk => clk,
    botao => btn_start,
    result => s_start);

dp_seg0: entity work.disp_ss(Behavioral)
port map (
    numero => segmento, 
    saida => seg_out);

--DEFINIÇÕES DE CONTAGEM E SELEÇÃO DOS DISPLAYS
process(clk)
variable cont: integer := 0;
begin
    if rising_edge(clk) then
        if cont > 100000 then
				display_atual <= display_atual +1;
            cont := 0;
        else
            cont := cont + 1;
        end if;       
    end if;
end process;

segmento <= std_logic_vector(seg0) when display_atual = "00" else
            std_logic_vector(seg1) when display_atual = "01" else
            std_logic_vector(min0) when display_atual = "10" else
            std_logic_vector(min1);
				
disp_out <= "1110" when display_atual = "00" else
            "1101" when display_atual = "01" else
            "1011" when display_atual = "10" else
            "0111";
end Behavioral;