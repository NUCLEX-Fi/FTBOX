library ieee;
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

signal trig_i_int:std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_o_int:std_logic_vector(NBIT_TRIG-1 downto 0);


type MATCH_ARRAY is array(0 to NBIT_TRIG -1) of std_logic_vector(NBIT_DATAIN -1 downto 0); ----array di vettori di segnali,che cattura il valore di ogni singolo contatore
signal TO_MATCHER: MATCH_ARRAY;

type div_factor_array is array(0 to NBIT_trig-1)of std_logic_vector(NBIT_DATAIN-1 downto 0);
signal div_factor :div_factor_array;
signal counter_reset : std_logic_vector(nbit_trig -1 downto 0);

-- aggiunta possibilita di mascherare i trigger nel downscaler gab 2010-4-26

signal trig_mask : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trg_o_premask : std_logic_vector(NBIT_TRIG-1 downto 0);

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


component counter16


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
conta : counter16
		port map(
				 clock_in =>trig_i_int(kcounter),
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


trig_i_int<=TRG_I;
TRG_O<=trig_o_int;
trig_o_int <= trg_o_premask and trig_mask;

downscaler:process(rst,clk)
BEGIN


	
	if(rst = '1')then
		selector <='0';
		CICLO_reset:FOR I IN NBIT_TRIG-1 DOWNTO 0 LOOP
			counter_reset(i) <= '1';
--			trg_o(i) <= '0';
			trg_o_premask(i) <= '0';
			trig_mask(i) <= '1';
			data_out(i) <= '0';
			div_factor(i)(NBIT_DATAIN-1 downto 1) <= (others => '0');
			div_factor(i)(0) <= '1';
		end loop;
	
	elsIF RISING_EDGE(CLK)THEN
		selector <='0';
		CICLO:FOR I IN NBIT_TRIG-1 DOWNTO 0 LOOP
			
			counter_reset(i) <= '0';
			if((to_integer(unsigned(address)) = (base_addr+ 16 + 4*i))AND N_RD ='1'  -- it was 2*i in V1495
			                 AND USR_ACCESS = '1') then		
							data_out <= div_factor(i);
							selector <='1';
			elsif((to_integer(unsigned(address)) = (base_addr))AND N_RD ='1'
			                 AND USR_ACCESS = '1') then		
							data_out(NBIT_TRIG-1 downto 0) <= trig_mask;
							selector <='1';
			end if;
			if((to_integer(unsigned(address)) = (base_addr+ 16 + 4*i))AND N_WR ='1'   -- it was 2*i in V1495
			                 AND USR_ACCESS = '1') then		
							div_factor(i) <= data_in;
							counter_reset(i) <= '1'; -- si resetta ogni volta che si cambia riduzione gab 2010-4-26
			elsif((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1'
			                 AND USR_ACCESS = '1') then		
							trig_mask <= data_in(NBIT_TRIG-1 downto 0);
			end if;
			trg_o_premask(i) <= '0';
			IF(CONV_INTEGER((TO_MATCHER(I))) = conv_INTEGER(div_factor(i)))THEN
				--if (conv_integer((to_matcher(i))) = compare(i)) then
				if(conv_integer(div_factor(i)) /= 0 ) then
					trg_o_premask(i)<= '1';
				end if;
				counter_reset(i) <= '1';
			end if;
		end loop;
	end if;
	
	
	
end process downscaler;
					   
end Behavioral;
