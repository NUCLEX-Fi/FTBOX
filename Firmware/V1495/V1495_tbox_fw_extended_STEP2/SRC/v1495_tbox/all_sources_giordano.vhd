library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity trigger_box is
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    Port ( 
		SUBTRG_INPUT_32 : in STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 downto 0);
--		TRG_INPUT_8: in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0);
		DEBUG_OUTPUT : out STD_LOGIC_VECTOR(NBIT_DEBUG-1 downto 0);
		MAINTRG : out  STD_LOGIC;
		CLK : in STD_LOGIC;
		RST: in STD_LOGIC;
		VETO_SIGNAL : in STD_LOGIC;
		PATTERN : OUT STD_LOGIC_VECTOR(NBIT_TRIG -1 downto 0);
		PATTERN_SERIAL : OUT STD_LOGIC;
		----------------------------BUS
		address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
		data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
		data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
		n_rd : in STD_LOGIC;
		n_wr : in STD_LOGIC;
		USR_ACCESS : in STD_LOGIC;
		selector : out STD_LOGIC
	    ------------------------------
	    );
 end trigger_box;

architecture Behavioral of trigger_box is

component data_mux 
	port(clock : in std_logic;
         reset : in std_logic;
         sel_0 : in std_logic;
         data_in_0 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_1 : in std_logic;
         data_in_1 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_2 : in std_logic;
         data_in_2 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_3 : in std_logic;
         data_in_3 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_4 : in std_logic;
         data_in_4 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_5 : in std_logic;
         data_in_5 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_6 : in std_logic;
         data_in_6 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         sel_7 : in std_logic;
         data_in_7 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
         --
         data_out : out std_logic_vector (NBIT_DATAOUT-1 downto 0);
         ce_data : in std_logic;
         selector : out std_logic
   );
end component;

component Scaler
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    port(clock: in  STD_LOGIC;                   --- Ingresso di clock.(rise edge.)
         reset: in  STD_LOGIC;						-- Ingresso di reset (att. alto.).
         fetch: in  std_logic_vector(NBIT_TRIG-1 downto 0);					-- Ingresso valore dal bus principale linea_0
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out  STD_LOGIC
	     -------------------------------
		);
end component;

component Resolving_Time
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    port(SUBTRG_I : in STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 downto 0); ---da cambiare dimensione in 32 bit
		 SUBTRG_O : out STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 downto 0);
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out  STD_LOGIC
	     ------------------------------
		 );
end component;

component Logic_Matrix
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    port(SUBTRG_I : in std_logic_vector(NBIT_SUBTRIG-1 downto 0);
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out  STD_LOGIC
	     ------------------------------
		 );	 	
end component;

component Busy
    port(TRG_I : in std_logic_vector(NBIT_TRIG-1 downto 0);
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 VETO_SIGNAL : in STD_LOGIC
		 );
end component;

component DownScaler
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(TRG_I : in std_logic_vector(NBIT_TRIG-1 downto 0);
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		 n_rd : in  STD_LOGIC;		
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out  STD_LOGIC
	     ------------------------------
		);	 	
end component;

component Trg_And_Pattern
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    port(
		 TRG_I : in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 MAINTRG : out STD_LOGIC;
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 VETO: in STD_LOGIC;
		 PATTERN : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 PATTERN_SERIAL : out STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out STD_LOGIC
	    ------------------------------
		 );    
end component;

signal subtriggers_32 : std_logic_vector(NBIT_SUBTRIG-1 downto 0); ----segnale sincronizzato a dovere
signal triggers_8 :std_logic_vector(NBIT_TRIG-1 downto 0);
signal to_muxsel_0,to_muxsel_1,to_muxsel_2,to_muxsel_3,to_muxsel_4,to_muxsel_6,to_muxsel_7: std_logic;
signal to_muxdata_0,to_muxdata_1,to_muxdata_2,to_muxdata_3,to_muxdata_4,to_muxdata_6,to_muxdata_7 : std_logic_vector(NBIT_DATAOUT-1 downto 0);
signal from_resolving_time : std_logic_vector(NBIT_SUBTRIG-1 downto 0);
signal from_logic_matrix : std_logic_vector(NBIT_TRIG-1 downto 0);
signal from_busy : std_logic_vector(NBIT_TRIG-1 downto 0);
signal from_downscaler :std_logic_vector(NBIT_TRIG-1 downto 0);
attribute keep: boolean;
attribute keep of from_resolving_time:signal is true;

signal ctrl_register : std_logic_vector(7 downto 0);
signal selector_mux, selector_tbox : std_logic;
signal data_out_mux, data_out_tbox :std_logic_vector(NBIT_DATAIN-1 downto 0);
signal from_trg_and_pat : std_logic_vector(NBIT_DEBUG-1 downto 0);

signal bit_pattern :std_logic_vector(NBIT_DEBUG-1 downto 0);

signal local_rst : std_logic;

begin

-- versione sync che si limita a campionare gli ingressi
-- e puï¿½ non vedere ingressi di durata minore del CLK
--	sync : process(CLK, RST)
--		begin
--			if RST='1' then
--			elsif CLK'event and CLK='1' then 
--				subtriggers_32 <= SUBTRG_INPUT_32;
--			end if;
--    end process sync;

local_rst <= RST or ctrl_register(7);

------------- Instantiate Multiplexer:
 dataoutmux: data_mux
		port map(clock => CLK,
				reset => local_rst,
				data_in_0 => to_muxdata_0,
				sel_0 => to_muxsel_0,
				data_in_1 => to_muxdata_1,
				sel_1 => to_muxsel_1,
				data_in_2 => to_muxdata_2,
				sel_2 => to_muxsel_2,
				data_in_3 => to_muxdata_3,
				sel_3 => to_muxsel_3,
				data_in_4 => to_muxdata_4,
				sel_4 => to_muxsel_4,
				data_in_5 => (others => '0'),
				sel_5 => '0',
				data_in_6 => to_muxdata_6,
				sel_6 => to_muxsel_6,
				data_in_7 => to_muxdata_7,
				sel_7 => to_muxsel_7,
				ce_data =>n_rd,
				data_out => data_out_mux,
				selector => selector_mux
			);


------------- instantiate Scaler_0:
    Scaler_0: Scaler
		generic map(base_addr => X"2500")
		port map(fetch => from_Logic_Matrix,
				clock => CLK,
				reset => local_rst,
				data_in => data_in,
				address => address,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_0,
				selector => to_muxsel_0
				);
    
------------- instantiate Scaler_1:
    Scaler_1: Scaler
		generic map(base_addr => X"2540")
		port map(
				fetch => From_Busy,
				clock => CLK,
				reset => local_rst,
				data_in => data_in,
				address => address,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_1,
				selector => to_muxsel_1
--	vme => DEBUG_OUTPUT
				);

------------- Instantiate Scaler_3:  
	Scaler_2: Scaler
		generic map(base_addr => X"2580")
		port map(
				fetch => From_DownScaler,
				clock => CLK,
				reset => local_rst,
				data_in => data_in,
				address => address,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_2,
				selector => to_muxsel_2
--	vme => DEBUG_OUTPUT
    );
    
------------- Instantiate Resolving_Time:
	Resolving_Time_1: Resolving_time
		generic map(base_addr => X"0100")
		port map(
--				SUBTRG_I => subtriggers_32,
				SUBTRG_I => SUBTRG_INPUT_32,
				SUBTRG_O => from_resolving_time,
				CLK => CLK,
				RST => local_rst,
				address => address,
				data_in =>data_in,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_3,
				selector => to_muxsel_3
				);

------------- Instantiate Logic_Matrix:
	Logic_Matrix_1: Logic_Matrix
		generic map(base_addr => X"0400")
		port map(
				SUBTRG_I => from_resolving_time,
				TRG_O => from_logic_matrix,
				CLK => CLK,
				RST => local_rst,
				address => address,
				data_in =>data_in,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_4,
				selector => to_muxsel_4
				);

------------- Instantiate Busy:
	Busy_1: Busy
		port map(
				TRG_I => from_logic_matrix,
				TRG_O => from_Busy,
				CLK => CLK,
				RST => local_rst,
				VETO_SIGNAL => VETO_SIGNAL
				
				);

  
  
------------- Instantiate DownScaler:
	DownScaler_1: DownScaler
		generic map(base_addr => X"2440")
		port map(
				 TRG_I => From_Busy,
				 TRG_O => From_DownScaler,
				 CLK => CLK,
				 RST => local_rst,
				 address => address,
				 data_in =>data_in,
				 data_out => to_muxdata_6,
				 n_rd => n_rd,
				 n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				 selector => to_muxsel_6
				);
	
------------- Instantiate Trig And Pattern
	Trg_And_Patter_1: Trg_And_Pattern
		generic map(base_addr => X"2480")
		port map(TRG_I => From_DownScaler,
				 CLK => CLK,
				 RST => local_rst,
				 MAINTRG => from_trg_and_pat(0),
				 pattern => bit_pattern(NBIT_TRIG-1 downto 0),
				 pattern_serial => pattern_serial,
				 address => address,
				 data_in =>data_in,
				 data_out => to_muxdata_7,
				 n_rd => n_rd,
				 n_wr => n_wr,
				 USR_ACCESS => USR_ACCESS,
				 selector => to_muxsel_7,
				 VETO => VETO_SIGNAL
				);

register_rw:PROCESS(RST,CLK)
BEGIN
	IF RST = '1' THEN
		ctrl_register <= X"05";
	ELSIF RISING_EDGE(CLK)THEN
		selector_tbox <='0';
		if (address = base_addr AND N_RD ='1'
			                 AND USR_ACCESS = '1') then	
				selector_tbox <='1';
				data_out_tbox(7 downto 0) <= ctrl_register;
		end if;	
		if(address = base_addr AND N_WR ='1'
			                 AND USR_ACCESS = '1') then	
				ctrl_register <= data_in(7 downto 0);
		end if;	
	
	END IF;	
END PROCESS register_rw;

 WITH ctrl_register select DEBUG_OUTPUT <=
                  SUBTRG_INPUT_32(NBIT_DEBUG-1 downto 0)      when X"01", 
                  from_resolving_time(NBIT_DEBUG-1 downto 0) when X"02",
                  from_logic_matrix(NBIT_DEBUG-1 downto 0) when X"03",
                  from_busy(NBIT_DEBUG-1 downto 0) when X"04",
                  from_downscaler(NBIT_DEBUG-1 downto 0) when X"05",
                  from_trg_and_pat  when X"06",
                  bit_pattern  when X"07",
                  (others =>'1') when X"08",
                  (others=>'0') when others;

--  DEBUG_OUTPUT <= subtriggers_32(NBIT_DEBUG-1downto 0)        when ctrl_register = X"1" else
--                  from_resolving_time(NBIT_DEBUG-1downto 0)   when ctrl_register = X"2" else
--                  from_logic_matrix(NBIT_DEBUG-1downto 0)     when ctrl_register = X"3" else
--                  from_busy(NBIT_DEBUG-1downto 0)             when ctrl_register = X"4" else
--                  from_downscaler(NBIT_DEBUG-1downto 0)       when ctrl_register = X"5"
--              else
--                 (others =>'0');

selector <= selector_mux OR selector_tbox;
data_out <= data_out_mux when selector_mux = '1' else
             data_out_tbox when selector_tbox = '1' else
             (others => '0');

MAINTRG <= from_trg_and_pat(0);

pattern <= bit_pattern(NBIT_TRIG-1 downto 0);             

end Behavioral;library ieee;
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
signal counter_reset_del : std_logic_vector(NBIT_SUBTRIG-1 downto 0);
--signal counter_reset_wid : std_logic_vector(NBIT_SUBTRIG-1 downto 0);
signal resolve_out :std_logic_vector(NBIT_SUBTRIG-1 downto 0); ---segnale temporaneo che rappresenta il risultato da mandare in output
SIGNAL reset_sync_del: STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0); 
SIGNAL reset_sync_wid: STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0); 
SIGNAL counter_start_wid:  STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0); ---segnale che,settato a 1,"dovrebbe" stimolare l'attivazione del processo di conta 
SIGNAL counter_start_del:  STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0); ---segnale che,settato a 1,"dovrebbe" stimolare l'attivazione del processo di conta 
type MATCH_ARRAY is array(0 to NBIT_SUBTRIG -1) of std_logic_vector(COUNTER_BUF-1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal TO_MATCHER: MATCH_ARRAY;
signal register_data_out:std_logic_vector(NBIT_DATAOUT-1 DOWNTO 0);

type delay_array is array(0 to NBIT_SUBTRIG -1) of std_logic_vector(COUNTER_BUF-1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal delay : delay_array;
signal from_delay_counter : delay_array;
--signal compare_zero : std_logic_vector(COUNTER_BUF-1 downto 0);

SIGNAL subtrig_latch:  STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 DOWNTO 0);

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

contatori: for kcounter in NBIT_SUBTRIG-1 downto 0 generate
conta : simple_counter
		port map(clock => CLK,
				 cnt_en =>counter_start_wid(Kcounter),
				 sset => not counter_start_wid(Kcounter),
				 sclr => '0', -- counter_reset_wid(kcounter),
				 q => To_matcher(Kcounter)
				 );
	
	end generate contatori;
	
delay_counters: for kcounter in NBIT_SUBTRIG-1 downto 0 generate
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
CICLO:FOR i IN NBIT_SUBTRIG-1 DOWNTO 0 GENERATE
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

DELAY_WIDTH:FOR i IN NBIT_SUBTRIG-1 DOWNTO 0 GENERATE
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
							if(subtrig_latch(i) = '1') then 
								counter_start_del(i) <='1';
							end if;
							IF(conv_integer((from_delay_counter(i))) = conv_integer(delay(i)))THEN 
								counter_start_del(i) <='0';
								counter_reset_del(i) <= '1';
								counter_start_wid(i) <='1';
								resolve_out(i) <= '1';
--								reset_sync_del(i) <= '1';
							end if;
--					END IF;
				ELSE
					IF(conv_integer((to_matcher(i))) = conv_integer(register_data_out))THEN 
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



DECODE_ADDR:PROCESS(CLK,RST)
BEGIN
	IF(RST = '1') THEN
		register_data_out(NBIT_DATAOUT-1 DOWNTO 3) <= (others => '0');
		register_data_out(0) <= '0';
		register_data_out(1) <= '0'; 
		register_data_out(2) <= '1';
		
		
		CICLO:FOR I IN NBIT_SUBTRIG-1 DOWNTO 0 LOOP
			delay(i) <= std_logic_vector(to_unsigned(1,COUNTER_BUF));
		end loop;
		
	ELSIF RISING_EDGE(CLK)THEN
		
		selector <='0';
			
		if((to_integer(unsigned(address)) = (base_addr+256))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then	
				selector <='1';
				data_out <= register_data_out;
		end if;	
		if((to_integer(unsigned(address)) = (base_addr+256))AND N_WR ='1'
			                 AND USR_ACCESS = '1') then	
				register_data_out <= data_in;
		end if;	
		
		CICLOADDR:FOR I IN NBIT_SUBTRIG-1 DOWNTO 0 LOOP

			if((to_integer(unsigned(address)) = (base_addr+2*i))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then	
				selector <='1';
				data_out(COUNTER_BUF-1 downto 0) <= delay(i);
			end if;	
			if((to_integer(unsigned(address)) = (base_addr+2*i))AND N_WR ='1'
			                 AND USR_ACCESS = '1') then	
			    if(conv_integer(data_in(COUNTER_BUF-1 downto 0)) = 0) then
					delay(i) <= std_logic_vector(to_unsigned(1,COUNTER_BUF));
				else
					delay(i) <= data_in(COUNTER_BUF-1 downto 0);
				end if;
			end if;	
		end loop;
	
	END IF;	
END PROCESS DECODE_ADDR;

end Behavioral;

library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Logic_Matrix is
	
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(SUBTRG_I : in std_logic_vector(NBIT_SUBTRIG-1 downto 0);
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT -1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out std_logic    
		 ------------------------------
		 );	 

end Logic_Matrix;


Architecture Behavioral of Logic_Matrix is
	

	
signal compare_to : std_logic_vector(NBIT_SUBTRIG - 1 downto 0);
signal reset :std_logic;
type input256_decision_array is array(0 to (NBIT_SUBTRIG * NBIT_TRIG - 1) )of std_logic_vector(1 downto 0); ---->  da 0 a 255
signal input256_matcher : input256_decision_array; ---array che raccoglie i valori dei 32 registri di selezione del tipo di ingresso(invertito,bloccato o normale)

type input8_decision_array is array (0 to (nbit_trig- 1)) of std_logic_vector(1 downto 0); ----> da 256 a 263
signal input8_matcher : input8_decision_array;  ---array che raccoglie i valori degli 8 registri di selezione del tipo di uscita finale

type to_or_array_signal is array (0 to Nbit_trig - 1) of std_logic_vector(nbit_subtrig - 1  downto 0);
signal to_or_array : to_or_array_signal;

signal or_output : std_logic_vector(0 to nbit_trig - 1);
	
BEGIN 
	
compare_to <= (others => '0');

	Selection: process(clk,rst,input256_matcher,subtrg_i,to_or_array,compare_to,input8_matcher,or_output)
		begin
				or_input_decisor:for j in nbit_trig-1 downto 0 loop
				
					FOR I IN NBIT_SUBTRIG-1 DOWNTO 0 LOOP 
																				------DA 31 A 0: ciclo che stabilisce che tipo di segnale deve giungere all'or generale dall'input
						case (CONV_INTEGER(input256_matcher((32*j)+i)))is		------Logica:
							when 1 => to_or_array(j)(i) <= subtrg_i(i);			------01 passa il segnale così com'è
							when 2 => to_or_array(j)(i) <= (not subtrg_i(i));	------10 passa il segnale invertito
							when others => to_or_array(j)(i) <= '0';			------00,11 non passa niente
						end case;
						if(to_or_array(j) = compare_to)	then					---ciclo successivo, confronto tra tutti i segnali con lo std_logic_vector compare_to che contiene solo 0
								or_output(j) <= '0'; 
						else 
								or_output(j) <= '1';
						end if;
					end loop;
				end loop;
				
				
				output_decisor :for i in NBIT_TRIG- 1 downto 0 loop --- DA 7 a 0:ciclo che stabilisce quali segnali andranno all'output
					case (CONV_INTEGER(input8_matcher(i))) is
						when 1 => trg_o(i) <= or_output(i);				----01 passa il segnale così com'è
						when 2 => trg_o(i)  <=  not or_output(i);			----10 passa il segnale invertito
						when others => trg_o(i) <= '0';												----00 e 11 non passa niente
					end case;
				
				end loop;
	end process selection;
	
	
	registers: process(clk,rst)
	
		begin
			
			
			if (RST = '1')then
																				-----Reset dei vari array di memorizzazione
				selector <='0';
				input256_matcher <= ( 35 downto 34 => "01", 1 downto 0 => "10", others =>"00");
				input8_matcher <= (0 => "10", 1 => "01" , others => "00");
				data_out <= (others => '0');
--				for i in ((NBIT_SUBTRIG*NBIT_TRIG)-1) DOWNTO 0 loop	
--					for j in 1 downto 0 loop
--						input256_matcher(i)(j) <='0';
--					end loop;
--				end loop;
--
--				for i in (nbit_trig - 1) DOWNTO 0 loop
--					for j in 1 downto 0 loop
--						input8_matcher(i)(j) <='0';
--					end loop;
--				end loop;
				
			elsif rising_edge(clk)then
				selector <='0';
																						-----Decodifica dell'indirizzo:
				read_AND_WRITE256: for i in 0 TO (NBIT_SUBTRIG*NBIT_TRIG-1) loop			-----Da 0 a 255 scrive o legge sull'input256_matcher
						if((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then		
							data_out(1 downto 0) <= input256_matcher(i);
							selector <='1';
						ELSIF ((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_WR ='1'
			                 AND USR_ACCESS = '1')THEN
							INPUT256_MATCHER(I) <= DATA_IN( 1 DOWNTO 0);
						END IF;
					end loop;
-- si lasciano 8192 indirizzi fra input e output (128 input * 32 output * 2 byte)
				read_AND_WRITE8: for i in 0 to (NBIT_TRIG - 1) loop	-----da 0 a 7 scrive o legge sull'input8_matcher{
						if((to_integer(unsigned(address)) = (base_addr+ 8192 + 2*i))AND N_RD ='1' AND USR_ACCESS = '1') then			
							data_out(1 downto 0) <= input8_matcher(i);
							selector <='1';
						ELSIF ((to_integer(unsigned(address)) = (base_addr+ 8192 + 2*i))AND N_WR ='1' AND USR_ACCESS = '1')THEN
							INPUT8_MATCHER(I) <= DATA_IN( 1 DOWNTO 0 );
						END IF;
				end loop;
				
				
			
		end if;
	end process registers;

	
end Behavioral;library ieee;
--library vector;                   -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Busy is 
	
	port(TRG_I : in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); ---da cambiare dimensione in 32 bit
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0);
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 VETO_SIGNAL : in STD_LOGIC
		 );
	end Busy;

Architecture Behavioral of Busy is
begin

process(clk,rst,veto_signal)
begin
		if (Veto_signal = '1')then
				TRG_O <= (others =>'0');
		else
			TRG_O <= TRG_I;
		end if;end process;
end Behavioral;library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;


entity DownScaler is

	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(TRG_I : in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); ---da cambiare dimensione in 32 bit
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0);
		 RST : in STD_LOGIC;
		 CLK :in Std_Logic;
		 ----------------------------BUS
		address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
		data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
		data_out: out STD_LOGIC_VECTOR(NBIT_DATAout-1 downto 0);
		n_rd : in  STD_LOGIC;
		n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		selector: out  STD_LOGIC
		-------------------------------
		); 

end DownScaler;

Architecture Behavioral of DownScaler is

type MATCH_ARRAY is array(0 to NBIT_TRIG -1) of std_logic_vector(NBIT_DATAIN -1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal TO_MATCHER: MATCH_ARRAY;

type div_factor_array is array(0 to NBIT_trig-1)of std_logic_vector(NBIT_DATAIN-1 downto 0);
signal div_factor :div_factor_array;
signal counter_reset : std_logic_vector(nbit_trig -1 downto 0);


--COMPONENT BIT_REGISTER_16 
--
--	PORT(  CLOCK: IN STD_LOGIC;
--			RESET: IN STD_LOGIC;
--			----------------------------BUS
--			address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
--			data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
--			data_out: out STD_LOGIC_VECTOR(NBIT_DATAout-1 downto 0);
--			n_rd : in  STD_LOGIC;
--			n_wr : in  STD_LOGIC;
--			selector: out  STD_LOGIC
--		);
--end component;


component counter


	port(
         reset    : in std_logic;
         clock_in : in std_logic;
         value_out : out std_logic_vector(NBIT_DATAout-1 downto 0)
         
         );

end component; 

begin
--compare <= (0 => 2, 1 => 4, others => 1) after 200 ns;
--------------------------Instantiate Counter:
contatori: for kcounter in NBIT_TRIG - 1 downto 0 generate
conta : counter
		port map(
				 clock_in =>trg_I(kcounter),
				 reset => counter_reset(kcounter),
				 value_out => To_matcher(Kcounter)
				 );
	
	end generate contatori;

--------------------------Instantiate 16bitregister

--bitregister_16:for i in 0 to Nbit_trig -1 generate
--
--conta: BIT_REGISTER_16
--			port map (clock => clk,
--					  reset =>rst,
--					  address => address,
--					  data_in => data_in,
--					  data_out=> div_factor(i),
--					  n_rd =>n_rd,
--					  n_wr =>n_wr
--					  
--					  );
--
--end generate bitregister_16;

-------------------------Start Downscaling:

downscaler:process(rst,clk)
BEGIN


	
	if(rst = '1')then
		selector <='0';
		CICLO_reset:FOR I IN NBIT_TRIG-1 DOWNTO 0 LOOP
			counter_reset(i) <= '1';
			trg_o(i) <= '0';
			data_out(i) <= '0';
			div_factor(i)(NBIT_DATAIN-1 downto 1) <= (others => '0');
			div_factor(i)(0) <= '1';
		end loop;
	
	elsIF RISING_EDGE(CLK)THEN
		selector <='0';
		CICLO:FOR I IN NBIT_TRIG-1 DOWNTO 0 LOOP
			
			counter_reset(i) <= '0';
			if((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then		
							data_out <= div_factor(i);
							selector <='1';
			end if;
			if((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_WR ='1'
			                 AND USR_ACCESS = '1') then		
							div_factor(i) <= data_in;
			end if;
			trg_o(i) <= '0';
			IF(CONV_INTEGER((TO_MATCHER(I))) = conv_INTEGER(div_factor(i)))THEN
				--if (conv_integer((to_matcher(i))) = compare(i)) then
				if(conv_integer(div_factor(i)) /= 0 ) then
					trg_o(i)<= '1';
				end if;
				counter_reset(i) <= '1';
			end if;
		end loop;
	end if;
	
	
	
end process downscaler;
					   
end Behavioral;library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Trg_And_Pattern is  
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(TRG_I : in STD_LOGIC_VECTOR(Nbit_trig -1 downto 0); 
		MAINTRG : out STD_LOGIC;
		CLK : in STD_LOGIC;
		RST : in STD_LOGIC;
		Veto:in std_logic; 
		pattern: out std_logic_vector(NBIT_TRIG -1 downto 0);
		pattern_serial: out std_logic;
		----------------------------BUS
		address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		n_rd : in  STD_LOGIC;
		n_wr : in  STD_LOGIC;
		USR_ACCESS : in STD_LOGIC;
		selector: out  STD_LOGIC
		------------------------------
		);
end Trg_And_Pattern;   

Architecture Behavioral of Trg_And_Pattern is

component trigger_ff IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC ;
		enable		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC 
	);
end component;

component simple_counter is
	
	PORT
	(
		clock		: IN STD_LOGIC ;
		cnt_en		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		sset		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
		
end component; 

--signal set : std_logic;
--signal counter_start : std_logic;
signal counter_reset : std_logic;
signal bit_pattern : std_logic_vector(NBIT_TRIG-1 downto 0);
signal compare_to : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_mask : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_masked : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_delayed : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_delayed1 : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trg_or : std_logic;
signal cpu_aclr : std_logic;
signal counted_value : std_logic_vector (NBIT_DATAOUT -1 downto 0 ); ----contiene il risultato del contatore associato al maintrigger
signal register_data : std_logic_vector (NBIT_DATAOUT -1 downto 0); 
signal mainout : std_logic;
signal reset_latch : std_logic;

signal bit_pattern_sbuff : std_logic_vector(3+8+NBIT_TRIG-1 downto 0);
signal serial_aclr : std_logic; -- to clear bit pattern after serial transmission

begin

bit_pattern_sbuff(NBIT_TRIG-1 downto 0) <= bit_pattern;
bit_pattern_sbuff(10+NBIT_TRIG) <='1';
bit_pattern_sbuff(9+NBIT_TRIG) <='0';
bit_pattern_sbuff(8+NBIT_TRIG) <='1';
bit_pattern_sbuff(7+NBIT_TRIG downto NBIT_TRIG) <= std_logic_vector(to_unsigned(NBIT_TRIG,8));


------istantiate Flip Flop:
	FF: for i in NBIT_TRIG - 1 downto 0 generate 
	flipflop: trigger_ff
	port map  ( aclr => cpu_aclr or serial_aclr or RST,
				enable => mainout,
				data => '1',
				clock => trig_delayed(i),
				q => bit_pattern(i)
			); 
	end generate ff;
---------------------------


-------instantiate counter for mainout:

 main_counter: simple_counter
 port map ( clock => CLK,
--			cnt_en => counter_start,
			cnt_en => mainout,
			sclr => '0', --counter_reset,
--			sset => not counter_start,
			sset => not mainout,
			q => counted_value(5 downto 0)
		  );
		  
	compare_to <= (others => '0');
	maintrg <= mainout;

    trig_masked <= trg_i AND trig_mask;
     
    pattern <= bit_pattern;
     
	trig_or :process(trig_masked,compare_to)
	begin
			if (trig_masked = compare_to) then      ----Or dei trigger
				trg_or <= '0';
			else 
				trg_or <= '1';
			end if;
	end process;

	decode:process(rst,clk)
		begin
			if (RST = '1')then
				selector <='0';	
				trig_mask <= (others => '1');
				register_data(NBIT_DATAOUT -1 downto 3) <= (others => '0');
				register_data(0) <= '0';
				register_data(1) <= '0'; 
				register_data(2) <= '1';
				
			elsif rising_edge(clk)then
				if((to_integer(unsigned(address)) = (base_addr))AND N_RD ='1' AND USR_ACCESS = '1') then	----loop per reperire il pattern
					data_out( NBIT_TRIG-1 downto 0) <= bit_pattern;
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +2))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out <= register_data;
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +4))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_TRIG-1 downto 0) <= trig_mask;
					selector <='1';
				else 
					selector <='0';
				end if;
				
				cpu_aclr <= '0';	
				
				if((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1' AND USR_ACCESS = '1') then    ----loop per azzerare i flip flop
					cpu_aclr <= '1';
					
				elsif((to_integer(unsigned(address)) = (base_addr + 2))AND N_WR ='1' AND USR_ACCESS = '1') then
					register_data <= data_in;
					
				elsif((to_integer(unsigned(address)) = (base_addr + 4))AND N_WR ='1' AND USR_ACCESS = '1') then
					trig_mask <= data_in(NBIT_TRIG-1 downto 0);
					
				end if;
				
			end if;
			
	end process decode;
	
	latching:process(reset_latch,trg_or,RST)
		begin
			if(reset_latch = '1' or RST = '1') then
--				set <='0';
--				counter_start <= '0';
				mainout <= '0';
			elsif rising_edge(trg_or) then 
--				if(set = '0')then
				if(mainout = '0')then
				mainout <= '1';
--					set <= '1';
--					counter_start <= '1';
				end if;
			end if;
	end process latching;
	
--	latching:process(CLK)
--		begin
--		if rising_edge(CLK) then
--			if(reset_latch = '1' or RST = '1') then
----				set <='0';
----				counter_start <= '0';
--				mainout <= '0';
--			elsif (trg_or = '1') then 
----				if(set = '0')then
--				if(mainout = '0')then
--					mainout <= '1';
----					set <= '1';
----					counter_start <= '1';
--				end if;
--			end if;
--		end if;
--	end process latching;

		setting:process(clk)
		begin
		if rising_edge(clk)then 
			trig_delayed1 <= trig_masked;
			trig_delayed <= trig_delayed1;
			reset_latch <= '0';
			counter_reset <= '0';
--			if(set = '1')then
			if(mainout = '1')then
				IF(conv_integer(register_data) = conv_integer(counted_value))THEN 
					reset_latch <= '1';
					counter_reset <= '1';
				end if;
			end if;
		end if;
	end process setting;

	serial_pattern:process(RST, clk)
	variable tx : Integer:=0;
	variable bitn : Integer:=0;
	variable waits : Integer:=0;
		begin
		if (RST = '1')then
			 tx := 0;
			 bitn := 0;
			 waits := 0;
			 pattern_serial  <= '0';
		elsif rising_edge(clk)then 
			serial_aclr <= '0';
			if( tx = 1 ) then
				if(bitn < NBIT_TRIG+3+8) then
					if(waits = 0) then
						pattern_serial <= bit_pattern_sbuff(NBIT_TRIG+3+8-1-bitn);
						bitn := bitn +1;
						waits := 8;  -- waits=DURATA DI UN SINGOLO BIT IN CLK PERIODS
					end if;
				end if;
				if(bitn <= NBIT_TRIG+3+8) then
						waits := waits-1;
				end if;
				if( bitn = NBIT_TRIG+3+8 and waits = 0) then
					tx := 0;
					bitn := 0;
					waits := 0;
					serial_aclr <= '1';
				end if;
			else
				pattern_serial  <= '0'; -- importante per evitare problemi baseline su DSP Florence			
			end if;
			if(reset_latch = '1') then
				tx := 1;
			end if;
		end if;
	end process serial_pattern;
	
end Behavioral;
library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;
use ieee.numeric_std.all;     			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Scaler is
	 
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(
		clock	: in  STD_LOGIC;	-- Ingresso di clock.(rise edge.)
		reset	: in  STD_LOGIC;	-- Ingresso di reset (att. alto.).
		fetch    :in  std_logic_vector(NBIT_TRIG-1 downto 0);	-- Ingresso valore dal bus principale linea_0
		  ----------------------------BUS
		  address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
		  data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
		  data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
		  n_rd : in  STD_LOGIC;
		  n_wr : in  STD_LOGIC;
		  USR_ACCESS : in STD_LOGIC;
		  selector: out  STD_LOGIC
		  --base_addr: in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0)
	     -------------------------------
		 );
end Scaler;

architecture behavioral of Scaler is
type cnt_array is array(0 to NBIT_TRIG -1) of std_logic_vector(NBIT_DATAOUT-1 downto 0);
signal cnt: cnt_array; 

--signal temp: std_logic_vector(15 downto 0);
--signal fetch_sig: std_logic_vector(fetch'RANGE);


component Counter
	
	
	port( 
		  reset : in std_logic;
          clock_in : in std_logic;
          value_out : out std_logic_vector(NBIT_SCALER-1 downto 0)
        );
end component;       
--	 sync : process(clock, reset)
--	 begin
--	   if reset='1' then
--	   elsif clock'event and clock='1' then 
--		fetch_sig <= fetch;
--	   end if;
--    end process sync;


begin

-------------------------------Instantiate Counter
contatori: for kcounter in NBIT_TRIG-1 downto 0 generate
       conta : Counter
       
      
       port map(
				reset => reset,
				clock_in  => fetch(kcounter),
                value_out => cnt(kcounter)
               );
end generate contatori;
---------------------------------
selection: process(clock,reset)
	begin	
	if (reset = '1')then 
		selector <='0';
	elsif rising_edge(clock)then
		selector <='0';
		if (n_rd = '1') and (USR_ACCESS = '1') then
			decode_addr: for i in 0 to NBIT_TRIG-1 loop
				if(to_integer(unsigned(address)) = (base_addr+  2*i)) then
					selector <= '1';
					data_out <=cnt(i);
				end if;
			end loop;
			else selector <='0';
		end if;
	end if;
end process selection;
	
end behavioral;										library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity data_mux is
	
   port( clock : in std_logic;
         reset : in std_logic;
         sel_0 : in std_logic;
         data_in_0 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_1 : in std_logic;
         data_in_1 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_2 : in std_logic;
         data_in_2 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_3 : in std_logic;
         data_in_3 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_4 : in std_logic;
         data_in_4 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_5 : in std_logic;
         data_in_5 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_6 : in std_logic;
         data_in_6 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_7 : in std_logic;
         data_in_7 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         --
         data_out : out std_logic_vector (NBIT_DATAOUT-1 downto 0);
         ce_data : in std_logic;
         selector : out std_logic
   );
end data_mux;

architecture behave of data_mux is

begin

 mux_process : process(ce_data,sel_0,sel_1,sel_2,sel_3,sel_4,sel_5,sel_6,sel_7,
        data_in_0,data_in_1,data_in_2,data_in_3,data_in_4,data_in_5,data_in_6,data_in_7)
 begin
     selector <= '0';
     if ce_data = '1' then
           if sel_0 = '1' then
              data_out <= data_in_0;
              selector <= '1';
           elsif sel_1 = '1' then
              data_out <= data_in_1;
              selector <= '1';
           elsif sel_2 = '1' then
              data_out <= data_in_2;
              selector <= '1';
           elsif sel_3 = '1' then
              data_out <= data_in_3;
              selector <= '1';
           elsif sel_4 = '1' then
              data_out <= data_in_4;
              selector <= '1';
           elsif sel_5 = '1' then
              data_out <= data_in_5;
              selector <= '1';
           elsif sel_6 = '1' then
              data_out <= data_in_6;
              selector <= '1';
           elsif sel_7 = '1' then
              data_out <= data_in_7;
              selector <= '1';
           else
              data_out <= (others =>'0');
              selector <= '0';
           end if;
      end if;
   end process;
end behave;

-----------------------------------------------library ieee;
--library vector;                   -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Counter is
	--generic(counter: integer:= 0);
	port(reset    : in std_logic;
         clock_in : in std_logic;
         --debug : out Integer;
         --debug_oldvalue: out Integer;
         value_out : out std_logic_vector(NBIT_SCALER-1 downto 0)
         );

end Counter;


architecture Behavioral of Counter is
signal counter : Integer :=0 ;

begin

count: process(clock_in,reset)
	
	variable temp : Integer:=0;						---variabile temporanea che memorizza il conteggio all'interno del processo

		begin
		if (reset = '1')then
			 temp := 0;
	    elsif(rising_edge(clock_in))then
				temp := temp + 1;
			end if;
  	    counter <= temp;
	end process count;
	value_out <= std_logic_vector(to_unsigned(counter,NBIT_DATAOUT));


end behavioral;-- megafunction wizard: %LPM_COUNTER%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: lpm_counter 

-- ============================================================
-- File Name: simple_counter.vhd
-- Megafunction Name(s):
-- 			lpm_counter
--
-- Simulation Library Files(s):
-- 			lpm
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 9.1 Build 222 10/21/2009 SJ Web Edition
-- ************************************************************


--Copyright (C) 1991-2009 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY lpm;
USE lpm.all;

ENTITY simple_counter IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		cnt_en		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		sset		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
END simple_counter;


ARCHITECTURE SYN OF simple_counter IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (5 DOWNTO 0);



	COMPONENT lpm_counter
	GENERIC (
		lpm_direction		: STRING;
		lpm_port_updown		: STRING;
		lpm_svalue		: STRING;
		lpm_type		: STRING;
		lpm_width		: NATURAL
	);
	PORT (
			sclr	: IN STD_LOGIC ;
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
			sset	: IN STD_LOGIC ;
			cnt_en	: IN STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	q    <= sub_wire0(5 DOWNTO 0);

	lpm_counter_component : lpm_counter
	GENERIC MAP (
		lpm_direction => "UP",
		lpm_port_updown => "PORT_UNUSED",
		lpm_svalue => "1",
		lpm_type => "LPM_COUNTER",
		lpm_width => 6
	)
	PORT MAP (
		sclr => sclr,
		clock => clock,
		sset => sset,
		cnt_en => cnt_en,
		q => sub_wire0
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: ACLR NUMERIC "0"
-- Retrieval info: PRIVATE: ALOAD NUMERIC "0"
-- Retrieval info: PRIVATE: ASET NUMERIC "0"
-- Retrieval info: PRIVATE: ASET_ALL1 NUMERIC "1"
-- Retrieval info: PRIVATE: CLK_EN NUMERIC "0"
-- Retrieval info: PRIVATE: CNT_EN NUMERIC "1"
-- Retrieval info: PRIVATE: CarryIn NUMERIC "0"
-- Retrieval info: PRIVATE: CarryOut NUMERIC "0"
-- Retrieval info: PRIVATE: Direction NUMERIC "0"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "APEX20KE"
-- Retrieval info: PRIVATE: ModulusCounter NUMERIC "0"
-- Retrieval info: PRIVATE: ModulusValue NUMERIC "0"
-- Retrieval info: PRIVATE: SCLR NUMERIC "1"
-- Retrieval info: PRIVATE: SLOAD NUMERIC "0"
-- Retrieval info: PRIVATE: SSET NUMERIC "1"
-- Retrieval info: PRIVATE: SSET_ALL1 NUMERIC "0"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "1"
-- Retrieval info: PRIVATE: nBit NUMERIC "6"
-- Retrieval info: CONSTANT: LPM_DIRECTION STRING "UP"
-- Retrieval info: CONSTANT: LPM_PORT_UPDOWN STRING "PORT_UNUSED"
-- Retrieval info: CONSTANT: LPM_SVALUE STRING "1"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_COUNTER"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "6"
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: cnt_en 0 0 0 0 INPUT NODEFVAL cnt_en
-- Retrieval info: USED_PORT: q 0 0 6 0 OUTPUT NODEFVAL q[5..0]
-- Retrieval info: USED_PORT: sclr 0 0 0 0 INPUT NODEFVAL sclr
-- Retrieval info: USED_PORT: sset 0 0 0 0 INPUT NODEFVAL sset
-- Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: q 0 0 6 0 @q 0 0 6 0
-- Retrieval info: CONNECT: @cnt_en 0 0 0 0 cnt_en 0 0 0 0
-- Retrieval info: CONNECT: @sclr 0 0 0 0 sclr 0 0 0 0
-- Retrieval info: CONNECT: @sset 0 0 0 0 sset 0 0 0 0
-- Retrieval info: LIBRARY: lpm lpm.lpm_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.bsf TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_inst.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_waveforms.html TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_wave*.jpg FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_syn.v TRUE
-- Retrieval info: LIB_FILE: lpm
