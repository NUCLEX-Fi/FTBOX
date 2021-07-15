library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;
use ieee.numeric_std.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Resolving_Time is
	
--	generic(DELAY: time := 2.0 ns);
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(SUBTRG_I : in STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 downto 0); ---da cambiare dimensione in 32 bit
		 SUBTRG_O : out std_logic_vector(NBIT_SUBTRIG-1 downto 0);
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out  STD_LOGIC
	    ------------------------------
		 );

end Resolving_Time;

Architecture Behavioral of Resolving_Time is

 
--signal resolving_time : integer :=10;
signal counter_reset : std_logic_vector(NBIT_SUBTRIG-1 downto 0);
signal resolve_out :std_logic_vector(NBIT_SUBTRIG-1 downto 0); ---segnale temporaneo che rappresenta il risultato da mandare in output
SIGNAL FETCH_IN: STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0);    ----segnale temporaneo che proviene dall'input principale
SIGNAL COUNTER_START:  STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0); ---segnale che,settato a 1,"dovrebbe" stimolare l'attivazione del processo di conta 
type MATCH_ARRAY is array(0 to NBIT_SUBTRIG -1) of std_logic_vector(Counter_buf-1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal TO_MATCHER: MATCH_ARRAY;
signal register_data_out:std_logic_vector(NBIT_DATAOUT-1 DOWNTO 0);

------------------------Components List

--COMPONENT BIT_REGISTER_16 
--
--	PORT(  	Din: IN STD_LOGIC_VECTOR (NBIT_DATAIN-1 DOWNTO 0);
--			CLOCK: IN STD_LOGIC;
--			RESET: IN STD_LOGIC;
--			DOut: OUT STD_LOGIC_VECTOR(NBIT_DATAout-1 DOWNTO 0)
--		);
--end component;

component simple_counter
	
	
	PORT
	(
		clock		: IN STD_LOGIC ;
		cnt_en		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
		
end component; 

BEGIN
---------------------------------Instantiate Input/Output signal

fetch_in <= SUBTRG_I; 
SUBTRG_O <= resolve_out;
 
---------------------------------Instantiate Counter:

contatori: for kcounter in NBIT_SUBTRIG-1 downto 0 generate
conta : simple_counter
		port map(clock => CLK,
				 cnt_en =>Counter_Start(Kcounter),
				 sclr => counter_reset(kcounter),
				 q => To_matcher(Kcounter)
				 );
	
	end generate contatori;
---------------------------------Instantiate 16bitregister:
--reg_0: bit_register_16

--	port map (clock => CLK,
--			  reset =>RST,
--			  Din => data_in,
--			  Dout => register_data_out
--			 );
----------------------------------------------------------

RESOLVING:PROCESS(CLK,RST)
BEGIN
	IF RISING_EDGE(CLK)THEN
		
		selector <='0';
		CICLO:FOR i IN NBIT_SUBTRIG-1 DOWNTO 0 LOOP 
			counter_reset(i) <= '0';
			IF  (fetch_in(i) = '1' and resolve_out(i) = '0')THEN		 ---se il segnale in input � uno,e il quello di output � 0 allora possiamo incominciare a contare e mandare in output il segnale prolungato
				counter_start(i) <= '1';
				resolve_out(i)<= '1';
			
--			elsif (fetch_in(i) = '0' and resolve_out(I) = '0')then		----se il segnale in input � 0 e quello di output � 0,l'output rimane come di default
--				counter_start(i) <= '0';
--				resolve_out(i) <='0';
--				
--			elsif(fetch_in(i) = '0' and resolve_out(I) = '1')then		-----se il segnale in input � 0 e quello di output � 1 vuol dire che il processo sta ancora prolungando il segnale in uscita,non abbiamo ancora raggiungo il resolving time
--				 resolve_out(i) <= '1';
--			
--			elsif (fetch_in(i) = '1' and resolve_out(I) = '1')then		-----ultimo caso
--				resolve_out(i) <='1'after delay;
--				counter_start(i) <='1';
--			
			END IF;
			
			IF(resolve_out(i) = '1' and 
			     conv_integer((to_matcher(i))) = conv_integer(register_data_out))THEN 
			--IF(CONV_INTEGER((TO_MATCHER(I))) = resolving_time)THEN
					counter_reset(i) <= '1';
					counter_start(i) <='0';
					resolve_out(i) <= '0';
			end if;

		end loop;
			
		if((to_integer(unsigned(address)) = (base_addr))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then	
				selector <='1';
				data_out <= register_data_out;
		end if;	
		if((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1'
			                 AND USR_ACCESS = '1') then	
				register_data_out <= data_in;
		end if;	
	
	END IF;	
END PROCESS resolving;

end Behavioral;