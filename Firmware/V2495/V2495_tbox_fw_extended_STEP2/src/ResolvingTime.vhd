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
	port(SUBTRG_I : in STD_LOGIC_VECTOR(127 downto 0); ---da cambiare dimensione in 32 bit
		 SUBTRG_O : out std_logic_vector(127 downto 0);
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
signal counter_reset_del : std_logic_vector(127 downto 0);
--signal counter_reset_wid : std_logic_vector(NBIT_SUBTRIG-1 downto 0);
signal resolve_out :std_logic_vector(127 downto 0); ---segnale temporaneo che rappresenta il risultato da mandare in output
SIGNAL reset_sync_del: STD_LOGIC_VECTOR(127 DOWNTO 0); 
SIGNAL reset_sync_wid: STD_LOGIC_VECTOR(127 DOWNTO 0); 
SIGNAL counter_start_wid:  STD_LOGIC_VECTOR(127 DOWNTO 0); ---segnale che,settato a 1,"dovrebbe" stimolare l'attivazione del processo di conta 
SIGNAL counter_start_del:  STD_LOGIC_VECTOR(127 DOWNTO 0); ---segnale che,settato a 1,"dovrebbe" stimolare l'attivazione del processo di conta 
type MATCH_ARRAY is array(0 to 127) of std_logic_vector(COUNTER_BUF-1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal TO_MATCHER: MATCH_ARRAY;
signal register_data_out:std_logic_vector(NBIT_DATAOUT-1 DOWNTO 0);

type delay_array is array(0 to 127) of std_logic_vector(COUNTER_BUF-1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal delay : delay_array;
signal from_delay_counter : delay_array;
--signal compare_zero : std_logic_vector(COUNTER_BUF-1 downto 0);

SIGNAL subtrig_latch:  STD_LOGIC_VECTOR(127 DOWNTO 0);

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
		sset		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
		
end component; 

component simple_counter_del
	
	
	PORT
	(
		clock		: IN STD_LOGIC ;
		cnt_en		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
		
end component; 

BEGIN

--compare_zero <= (others => '0');

---------------------------------Instantiate Input/Output signal

 
---------------------------------Instantiate Counter:

contatori: for kcounter in 127 downto 0 generate
conta : simple_counter
		port map(clock => CLK,
				 cnt_en =>counter_start_wid(Kcounter),
				 sset => not counter_start_wid(Kcounter),
				 sclr => '0', -- counter_reset_wid(kcounter),
				 q => To_matcher(Kcounter)
				 );
	
	end generate contatori;
	
delay_counters: for kcounter in 127 downto 0 generate
delay : simple_counter_del
		port map(clock => CLK,
				 cnt_en =>counter_start_del(Kcounter),
				 sclr => counter_reset_del(kcounter),
				 q => from_delay_counter(Kcounter)
				 );
	
	end generate delay_counters;

---------------------------------Instantiate 16bitregister:
--reg_0: bit_register_16

--	port map (clock => CLK,
--			  reset =>RST,
--			  Din => data_in,
--			  Dout => register_data_out
--			 );
----------------------------------------------------------

-- si potrebbe provare a far gestire SUBTRG_O a questo processo per evitare il
-- jitter, ma poi jittera la durata!
CICLO:FOR i IN 127 DOWNTO 0 GENERATE
		SYNC:PROCESS(CLK,RST,RESET_SYNC_DEL,SUBTRG_I)
		BEGIN
			IF (RST = '1') THEN
				subtrig_latch(i) <='0';
			ELSIF reset_sync_del(i) = '1' THEN
				subtrig_latch(i) <='0';
			ELSIF RISING_EDGE(subtrg_i(i))THEN
					subtrig_latch(i) <= '1';
			END IF;	
		END PROCESS SYNC;
END GENERATE;

DELAY_WIDTH:FOR i IN 127 DOWNTO 0 GENERATE
DELAYPROC:PROCESS(CLK,RST)
BEGIN
			IF (RST = '1') THEN
				reset_sync_del(i) <= '0';
				counter_reset_del(i) <= '1';
--				counter_reset_wid(i) <= '1';
				resolve_out(i) <= '0';
				counter_start_del(i) <='0';
				counter_start_wid(i) <='0';
			ELSIF RISING_EDGE(CLK)THEN
				reset_sync_del(i) <= '0';
				if(counter_start_del(i) = '1') then
					counter_reset_del(i) <= '0';
				else
					counter_reset_del(i) <= '1';
				end if;
--				if(counter_start_wid(i) = '1') then
--					counter_reset_wid(i) <= '0';
--				else
--					counter_reset_wid(i) <= '1';
--				end if;
				IF  (resolve_out(i) = '0')THEN
--					IF(conv_integer(delay(i)) = conv_integer(compare_zero))THEN 
--							if(subtrig_latch(i) = '1') then 
--								reset_sync_del(i) <= '1';
--								counter_start_wid(i) <='1';
--								counter_reset_del(i) <= '1';
--								counter_start_del(i) <='0';
--								resolve_out(i) <= '1';
--							end if;
--					ELSE
							if(subtrig_latch(i) = '1') then --start delay
								counter_start_del(i) <='1';
							end if;
							IF(conv_integer((from_delay_counter(i))) = conv_integer(delay(i)))THEN --delay enede, start window
								counter_start_del(i) <='0';
								counter_reset_del(i) <= '1';
								counter_start_wid(i) <='1';
								resolve_out(i) <= '1';
--								reset_sync_del(i) <= '1';
							end if;
--					END IF;
				ELSE
					IF(conv_integer((to_matcher(i))) = conv_integer(register_data_out))THEN --window ended
--						counter_reset_wid(i) <= '1';
						resolve_out(i)<= '0';
						counter_start_wid(i) <='0';
						reset_sync_del(i) <= '1';
					end if;
				end if;
			END IF;	
END PROCESS DELAYPROC;
END GENERATE;

SUBTRG_O <= resolve_out;
--SUBTRG_O <= subtrig_latch;
--UP to here we can simply modify by putting NBIT_SUBTRG=128

--completely rewritten the memory map, same addresses but different way of storing data OTTANELLI
--here starts the pain-> only 64 locations available:>commpression is needed. Only 6 bits are used for each delay->let's use each register to store two delays
DECODE_ADDR:PROCESS(CLK,RST)
BEGIN
	IF(RST = '1') THEN
		register_data_out(NBIT_DATAOUT-1 DOWNTO 3) <= (others => '0');
		register_data_out(0) <= '0';
		register_data_out(1) <= '0'; 
		register_data_out(2) <= '1';
		
		
		CICLO:FOR I IN 127 DOWNTO 0 LOOP
			delay(i) <= std_logic_vector(to_unsigned(1,COUNTER_BUF));
		end loop;
		
	ELSIF RISING_EDGE(CLK)THEN
		
		selector <='0';
		-- resolving time window	
		if((to_integer(unsigned(address)) = (base_addr+256))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then	
				selector <='1';
				data_out <= register_data_out;
		end if;	
		if((to_integer(unsigned(address)) = (base_addr+256))AND N_WR ='1'
			                 AND USR_ACCESS = '1') then	
				register_data_out <= data_in;
		end if;	
		
		--to_integer(shift_right(to_unsigned(NBIT_SUBTRIG),1)); takes NBIT_SUBTRIG and divide it by two
		CICLOADDR:FOR I IN NPOS_DELAY-1 DOWNTO 0 LOOP
			
			if((to_integer(unsigned(address)) = (base_addr+4*i))AND N_RD ='1'  -- it was 2*i in V1495
			                 AND USR_ACCESS = '1') then	
				selector <='1';
				data_out(COUNTER_BUF-1 downto 0) <= delay(2*i);--first delay
				data_out(COUNTER_BUF+7 downto 8) <= delay(2*i+1);--second delay
			end if;	
			if((to_integer(unsigned(address)) = (base_addr+4*i))AND N_WR ='1'   -- it was 2*i in V1495
			                 AND USR_ACCESS = '1') then	
				--read delay 1				  
			    if(conv_integer(data_in(COUNTER_BUF-1 downto 0)) = 0) then
					delay(2*i) <= std_logic_vector(to_unsigned(1,COUNTER_BUF));
				else
					delay(2*i) <= data_in(COUNTER_BUF-1 downto 0);
				end if;
				--read delay 2
				if(conv_integer(data_in(COUNTER_BUF+7 downto 8)) = 0) then
					delay(2*i+1) <= std_logic_vector(to_unsigned(1,COUNTER_BUF));
				else
					delay(2*i+1) <= data_in(COUNTER_BUF+7 downto 8);
				end if;
				
			end if;	
		end loop;
	
	END IF;	
END PROCESS DECODE_ADDR;

end Behavioral;

