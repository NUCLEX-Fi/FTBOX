library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity trigger_box is
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    Port ( 
		SUBTRG_INPUT_32 : in STD_LOGIC_VECTOR(127 downto 0);
--		TRG_INPUT_8: in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0);
		DEBUG_OUTPUT : out STD_LOGIC_VECTOR(NBIT_DEBUG-1 downto 0);
		MAINTRG : out  STD_LOGIC;
		RES_TIME : out  STD_LOGIC;
		CLK : in STD_LOGIC;
		RST: in STD_LOGIC;
--		VETO_SIGNAL : in STD_LOGIC;
		VETO_OUTPUT : out STD_LOGIC;  -- used when veto is internally generated and reset from CPU by accessing a register
		VETO_INPUT : in STD_LOGIC;  -- used when veto is not internally generated 
		VETO_SEL : out STD_LOGIC;  -- connected to ctrl_register(8)
		VETO_REG : out STD_LOGIC;  -- connected to ctrl_register(14)
		trigcodebit : out std_logic;
		IRQ_ENA : out STD_LOGIC;  -- connected to ctrl_register(8)
		PATTERN : OUT STD_LOGIC_VECTOR(NBIT_TRIG -1 downto 0);
		PATTERN_SERIAL : OUT STD_LOGIC;
		INT : OUT STD_LOGIC;
		CNTRL_REG : OUT STD_LOGIC_VECTOR(15 downto 0);
		CHC_TOT : IN STD_LOGIC_VECTOR(7 downto 0);
		----------------------------BUS
		address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
		data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
		data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
		n_rd : in STD_LOGIC;
		n_wr : in STD_LOGIC;
		USR_ACCESS : in STD_LOGIC
-- 		selector : out STD_LOGIC
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
         sel_8 : in std_logic;
         data_in_8 : in std_logic_vector ( NBIT_DATAOUT-1 downto 0);
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
    port(SUBTRG_I : in STD_LOGIC_VECTOR(127 downto 0); ---da cambiare dimensione in 32 bit
		 SUBTRG_O : out STD_LOGIC_VECTOR(127 downto 0);
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

component Logic_Matrix	--DIFFERENT PORT MAP OTTANELLI
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    port(SUBTRG_I : in std_logic_vector(127 downto 0);
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

component trigcode_generator 
port(
	increment : in std_logic;
	reset : in std_logic;
	valout : out std_logic_vector(15 downto 0)
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
		 inc_cntr : out std_logic;
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

component MainTrigGen is  
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(TRG_I : in STD_LOGIC; 
		MAINTRG : out STD_LOGIC;
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


component Logic_Analyzer
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    port(
		 INPUT : in STD_LOGIC_VECTOR(NBIT_DEBUG-1 downto 0); 
		 EXT_TRIGGER : in STD_LOGIC;
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
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

signal subtriggers_32 : std_logic_vector(127 downto 0); ----segnale sincronizzato a dovere
signal subtrig_input_ext :std_logic_vector(127 downto 0); --padded for multiplexer
signal triggers_8 :std_logic_vector(NBIT_TRIG-1 downto 0);
signal to_muxsel_0,to_muxsel_1,to_muxsel_2,to_muxsel_3,to_muxsel_4,to_muxsel_5,to_muxsel_6,to_muxsel_7,to_muxsel_8: std_logic;
signal to_muxdata_0,to_muxdata_1,to_muxdata_2,to_muxdata_3,to_muxdata_4,to_muxdata_5,to_muxdata_6,to_muxdata_7,to_muxdata_8 : std_logic_vector(NBIT_DATAOUT-1 downto 0);
signal from_resolving_time : std_logic_vector(127 downto 0);
signal from_resolving_time_ext :std_logic_vector(127 downto 0); --padded for multiplexer
signal from_logic_matrix : std_logic_vector(NBIT_TRIG-1 downto 0);
signal from_busy : std_logic_vector(NBIT_TRIG-1 downto 0);
signal from_downscaler :std_logic_vector(NBIT_TRIG-1 downto 0);
attribute keep: boolean;
attribute keep of from_resolving_time:signal is true;


-- ctrl_register(3 downto 0): controls debug mux output
-- ctrl_register(7): software reset 
-- ctrl_register(6): scalers reset
-- ctrl_register(5): masks external trigger of the Logic Analyzer
-- ctrl_register(8) : veto selector
--ctrl_register(9) : irq_ena
--ctrl_register(12 downto 11) : subset for trigger LA
--ctrl_register (4) : Redirect main output on port F if (1) otherwise on port C
--ctrl_register (10) : decide if additional inputs have to be in NIM (0) or TTL logic(1)
-- signal ctrl_register : std_logic_vector(7 downto 0);
--ctrl_register (13) : selects level for LEMO output (NIN (0) or TTL (1));
--ctrl_register (14) : Forced Veto
signal ctrl_register : std_logic_vector(15 downto 0);  -- now 16 bit to accomodate one bit for IRQ control and one for VETO (internal/external)


signal selector_mux, selector_tbox : std_logic;
signal data_out_mux, data_out_tbox :std_logic_vector(NBIT_DATAIN-1 downto 0);
signal from_trg_and_pat : std_logic_vector(NBIT_DEBUG-1 downto 0);

signal bit_pattern :std_logic_vector(NBIT_DEBUG-1 downto 0);

signal local_rst, MAINTRG_QUI : std_logic;
signal debug_signal : STD_LOGIC_VECTOR(NBIT_DEBUG-1 downto 0);
signal inc_cntr: std_logic;
signal veto_signal_qui : std_logic; -- veto signal (equal to internally generated veto if ctrl_register(8) = '1', otherwise comes from VETO_INPUT)
signal veto_signal_int : std_logic; -- internally generated VETO
signal set_veto_signal_int : std_logic; -- set veto using register
signal reset_veto_signal_int : std_logic; -- set veto using register

signal irq_signal_qui, reset_irq_signal_qui : std_logic;

signal forced_veto : std_logic; --managed by ctrl_reg(14) , disables trigger generation
signal reset_code : std_logic; --managed by ctrl_reg(15)

begin

Extender:process(SUBTRG_INPUT_32,from_resolving_time)
begin
	subtrig_input_ext<=SUBTRG_INPUT_32;
	from_resolving_time_ext<=from_resolving_time;
	
end process Extender;


--can stay as It is OTTANELLI
-- versione sync che si limita a campionare gli ingressi
-- e pu non vedere ingressi di durata minore del CLK
--	sync : process(CLK, RST)
--		begin
--			if RST='1' then
--			elsif CLK'event and CLK='1' then 
--				subtriggers_32 <= SUBTRG_INPUT_32;
--			end if;
--    end process sync;

CNTRL_REG<=ctrl_register;
local_rst <= RST or ctrl_register(7);
forced_veto<=ctrl_register(14);
reset_code<=ctrl_register(15);
veto_Reg<=forced_veto;

----------- flip flop for INT (IRQ) signal --can stay as It is OTTANELLI
	irq_flipflop: trigger_ff
	port map  ( 
			aclr =>  RST or reset_irq_signal_qui, 
				enable => '1',
				data => '1',
				clock => from_trg_and_pat(0), -- resolving time signal is now the actual trigger, which triggers also the IRQ
				q => irq_signal_qui
			); 


----------- flip flop for VETO signal --can stay as It is OTTANELLI
	veto_flipflop: trigger_ff
	port map  ( 
                aclr =>  RST or reset_veto_signal_int, 
				enable => '1',
				data => '1',
				clock => set_veto_signal_int or from_trg_and_pat(0), -- resolving time signal is now the actual trigger, MAINTRG_QUI is the validation
				q => veto_signal_int
			); 
------------- Instantiate Multiplexer: --can stay as It is OTTANELLI
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
				data_in_5 => to_muxdata_5,
				sel_5 => to_muxsel_5,
				data_in_6 => to_muxdata_6,
				sel_6 => to_muxsel_6,
				data_in_7 => to_muxdata_7,
				sel_7 => to_muxsel_7,
				data_in_8 => to_muxdata_8,
				sel_8 => to_muxsel_8,
				ce_data =>n_rd,
				data_out => data_out_mux,
				selector => selector_mux
			);


------------- instantiate Scaler_0: --can stay as It is OTTANELLI, will work on the first 8 bits
    Scaler_0: Scaler
		generic map(base_addr => INFNFI2_TBOX_SCALE0)
		port map(fetch => from_Logic_Matrix,
				clock => CLK,
				reset => local_rst or ctrl_register(6),
				data_in => data_in,
				address => address,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_0,
				selector => to_muxsel_0
				);
    
------------- instantiate Scaler_1: --can stay as It is OTTANELLI, will work on the first 8 bits
    Scaler_1: Scaler
		generic map(base_addr => INFNFI2_TBOX_SCALE1)
		port map(
				fetch => From_Busy,
				clock => CLK,
				reset => local_rst or ctrl_register(6),
				data_in => data_in,
				address => address,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_1,
				selector => to_muxsel_1
--	vme => DEBUG_OUTPUT
				);

------------- Instantiate Scaler_3:   --can stay as It is OTTANELLI, will work on the first 8 bits
	Scaler_2: Scaler
		generic map(base_addr => INFNFI2_TBOX_SCALE2)
		port map(
				fetch => From_DownScaler,
				clock => CLK,
				reset => local_rst or ctrl_register(6),
				data_in => data_in,
				address => address,
				n_rd => n_rd,
				n_wr => n_wr,
				USR_ACCESS => USR_ACCESS,
				data_out => to_muxdata_2,
				selector => to_muxsel_2
--	vme => DEBUG_OUTPUT
    );
    
------------- Instantiate Resolving_Time:  --can stay as It is OTTANELLI, variation is inside
	Resolving_Time_1: Resolving_time
		generic map(base_addr => INFNFI2_TBOX_GDGEN_DEL)
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

------------- Instantiate Logic_Matrix:    --Different port map OTTANELLI
	Logic_Matrix_1: Logic_Matrix
		generic map(base_addr => INFNFI2_TBOX_LMINPUT)
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
--changed port map OTTANELLI
	Busy_1: Busy
		port map(
				TRG_I => from_logic_matrix,
				TRG_O => from_Busy,
				CLK => CLK,
				RST => local_rst,
				VETO_SIGNAL => (veto_signal_qui and (not from_trg_and_pat(0))) or forced_veto -- per essere insensibili a veto durante res time Gab 2010-4-30
				
				);

  
  
------------- Instantiate DownScaler:
--changed port map OTTANELLI
	DownScaler_1: DownScaler
		generic map(base_addr => INFNFI2_TBOX_RED_BASE)
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
--changed port map OTTANELLI
	Trg_And_Patter_1: Trg_And_Pattern
		generic map(base_addr => INFNFI2_TBOX_BITPATTERN)
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
				 VETO => veto_signal_qui or forced_veto,
				 inc_cntr => inc_cntr
				);

	trigger_generator : MainTrigGen   
		generic map(base_addr => INFNFI2_TBOX_MAINTR_WID)
		port map(TRG_I => from_trg_and_pat(0),
				MAINTRG => MAINTRG_QUI,
				CLK=>CLK,
				RST => local_rst,
		----------------------------BUS
		 		address => address,
				 data_in =>data_in,
				 data_out => to_muxdata_8,
				 n_rd => n_rd,
				 n_wr => n_wr,
				 USR_ACCESS => USR_ACCESS,
				 selector => to_muxsel_8
		------------------------------
		);
		
		code_generator: trigcode_generator
		port map(
			increment =>inc_cntr,
			reset  => reset_code or local_rst,
			valout (15 downto 1)=> open,
			valout (0) => trigcodebit
		);

------------- Instantiate Logic Analyzer
	Logic_Analyzer_1: Logic_Analyzer
		generic map(base_addr => INFNFI2_TBOX_LOGIC_ANA_MEM)
		port map(INPUT => debug_signal,
				 EXT_TRIGGER=> from_trg_and_pat(0) AND ctrl_register(5),
				 CLK => CLK,
				 RST => local_rst,
				 address => address,
				 data_in =>data_in,
				 data_out => to_muxdata_5,
				 n_rd => n_rd,
				 n_wr => n_wr,
				 USR_ACCESS => USR_ACCESS,
				 selector => to_muxsel_5
				);


--global registers RW, keep as it is
register_rw:PROCESS(RST,CLK)
BEGIN
	IF RST = '1' THEN
--		ctrl_register <= X"05";
		ctrl_register <= X"0005";  -- default is no IRQ generation ON (bit 9 is '0'), external VETO (bit 8 is '0'), mux out from DownScaler (bits 3 downto 0)
		set_veto_signal_int <= '0'; 
		reset_veto_signal_int <= '0';
		reset_irq_signal_qui <= '0';
	ELSIF RISING_EDGE(CLK)THEN
		selector_tbox <='0';
		set_veto_signal_int <= '0';
		reset_veto_signal_int <= '0';
		reset_irq_signal_qui <= '0';
--		if (address = base_addr AND N_RD ='1'
--			                 AND USR_ACCESS = '1') then	
		if((to_integer(unsigned(address)) = (INFNFI2_BOARDMODEL))AND N_RD ='1' AND USR_ACCESS = '1') then
				selector_tbox <='1';
				data_out_tbox(15 downto 0) <= X"09BF";
		end if;	
		if( address = INFNFI2_BOARDDATA AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out_tbox(1 downto 0) <= "10";
					data_out_tbox(3 downto 2) <= "00";
					data_out_tbox(10 downto 4) <= "0000000"+CHC_TOT(6 downto 0);
					data_out_tbox(15 downto 11) <= "00000"+NBIT_TRIG;
					selector_tbox<='1';
		end if;
		if((to_integer(unsigned(address)) = (base_addr))AND N_RD ='1' AND USR_ACCESS = '1') then
				selector_tbox <='1';
--				data_out_tbox(7 downto 0) <= ctrl_register;
				data_out_tbox <= ctrl_register;
		end if;	
		--		if(address = base_addr AND N_WR ='1'
--			                 AND USR_ACCESS = '1') then	
		if((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1' AND USR_ACCESS = '1') then  
-- 				ctrl_register <= data_in(7 downto 0);
				ctrl_register <= data_in;
		end if;	
		if((to_integer(unsigned(address)) = (base_addr+4))AND N_WR ='1' AND USR_ACCESS = '1') then  -- writing to this register sets VETO
				set_veto_signal_int <= '1';
		end if;	
		if((to_integer(unsigned(address)) = (base_addr+8))AND N_WR ='1' AND USR_ACCESS = '1') then  -- writing to this register resets veto
				reset_veto_signal_int <= '1';
		end if;	
		if((to_integer(unsigned(address)) = (base_addr+12))AND N_WR ='1' AND USR_ACCESS = '1') then  -- writing to this register resets irq
				reset_irq_signal_qui <= '1';
		end if;	
	
	END IF;	
END PROCESS register_rw;



DEBUG_OUTPUT<=debug_signal;

debug_mux:PROCESS(RST,CLK,ctrl_register,from_resolving_time,subtrig_input_ext,from_resolving_time_ext,from_Logic_Matrix,veto_signal_qui,MAINTRG_QUI,from_trg_and_pat,from_busy,from_DownScaler,bit_pattern)
BEGIN
	debug_signal <= (others =>'0');
	if(ctrl_register(3 downto 0) = X"1") then
		case (ctrl_register (12 downto 11)) is
			when "00"=>
				debug_signal <= subtrig_input_ext(NBIT_DEBUG-1 downto 0);
			when "01"=>
				debug_signal <= subtrig_input_ext(2*NBIT_DEBUG-1 downto NBIT_DEBUG);
			when "10"=>
				debug_signal <= subtrig_input_ext(3*NBIT_DEBUG-1 downto 2*NBIT_DEBUG);
			when "11"=>
				debug_signal <= subtrig_input_ext(4*NBIT_DEBUG-1 downto 3*NBIT_DEBUG);
		end case;
	elsif(ctrl_register(3 downto 0) = X"2") then
		case (ctrl_register (12 downto 11)) is
			when "00"=>
				debug_signal <= from_resolving_time_ext(NBIT_DEBUG-1 downto 0);
			when "01"=>
				debug_signal <= from_resolving_time_ext(2*NBIT_DEBUG-1 downto NBIT_DEBUG);
			when "10"=>
				debug_signal <= from_resolving_time_ext(3*NBIT_DEBUG-1 downto 2*NBIT_DEBUG);
			when "11"=>
				debug_signal <= from_resolving_time_ext(4*NBIT_DEBUG-1 downto 3*NBIT_DEBUG);
		end case;
	elsif(ctrl_register(3 downto 0) = X"3") then
		debug_signal(NBIT_TRIG-1 downto 0) <= from_logic_matrix;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"4") then
		debug_signal(NBIT_TRIG-1 downto 0) <= from_busy;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"5") then
		debug_signal(NBIT_TRIG-1 downto 0) <= from_downscaler;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"6") then
		debug_signal <= bit_pattern ;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"7") then
		debug_signal(15 downto 0) <= from_resolving_time(15 downto 0) ;
		debug_signal(23 downto 16) <= from_logic_matrix(7 downto 0) ;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"8") then
		debug_signal(15 downto 0) <= from_resolving_time(31 downto 16) ;
		debug_signal(23 downto 16) <= from_logic_matrix(7 downto 0) ;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"9") then
		debug_signal(15 downto 0) <= from_resolving_time(15 downto 0) ;
		debug_signal(23 downto 16) <= from_downscaler(7 downto 0) ;
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"A") then
		debug_signal(15 downto 0) <= from_resolving_time(31 downto 16);
		debug_signal(23 downto 16) <= from_downscaler(7 downto 0);
		debug_signal(NBIT_DEBUG-1) <= veto_signal_qui;
		debug_signal(NBIT_DEBUG-2) <= MAINTRG_QUI;
		debug_signal(NBIT_DEBUG-3) <= from_trg_and_pat(0);
	elsif(ctrl_register(3 downto 0) = X"F") then
		debug_signal <= (others =>'1');
	end if;
END PROCESS debug_mux;

-- WITH ctrl_register select DEBUG_OUTPUT <=
--                  SUBTRG_INPUT_32(NBIT_DEBUG-1 downto 0)      when X"01", 
--                  from_resolving_time(NBIT_DEBUG-1 downto 0) when X"02",
--                  from_logic_matrix(NBIT_DEBUG-1 downto 0) when X"03",
--                  from_busy(NBIT_DEBUG-1 downto 0) when X"04",
--                  from_downscaler(NBIT_DEBUG-1 downto 0) when X"05",
--                  from_trg_and_pat  when X"06",
--                  bit_pattern  when X"07",
--                  (others =>'1') when X"08",
--                  (others=>'0') when others;

--  DEBUG_OUTPUT <= subtriggers_32(NBIT_DEBUG-1downto 0)        when ctrl_register = X"1" else
--                  from_resolving_time(NBIT_DEBUG-1downto 0)   when ctrl_register = X"2" else
--                  from_logic_matrix(NBIT_DEBUG-1downto 0)     when ctrl_register = X"3" else
--                  from_busy(NBIT_DEBUG-1downto 0)             when ctrl_register = X"4" else
--                  from_downscaler(NBIT_DEBUG-1downto 0)       when ctrl_register = X"5"
--              else
--                 (others =>'0');

--selector <= selector_mux OR selector_tbox;
data_out <= data_out_mux when selector_mux = '1' else
             data_out_tbox when selector_tbox = '1' else
             (others => '0');

veto_signal_qui <= veto_signal_int when ctrl_register(8) = '1' else VETO_INPUT; -- bit 8 of ctrl_register selects internal or external veto

VETO_OUTPUT <= veto_signal_int when ctrl_register(8) = '1' else 'Z'; -- veto is propagated to the output for monitoring
VETO_SEL <= ctrl_register(8);

-- INT <= irq_signal_qui;
INT <= irq_signal_qui;  
IRQ_ENA <= ctrl_register(9); -- bit 9 of ctrl_register enables IRQ generation (set to 1 to enable IRQ)
MAINTRG <= MAINTRG_QUI;
RES_TIME <= from_trg_and_pat(0);
pattern <= bit_pattern(NBIT_TRIG-1 downto 0); 

end Behavioral;
