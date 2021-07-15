library ieee;
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
signal bit_pattern, bit_pattern_register : std_logic_vector(NBIT_TRIG-1 downto 0);
signal compare_to : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_mask : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_masked : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_delayed : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trig_delayed1 : std_logic_vector(NBIT_TRIG-1 downto 0);
signal trg_or : std_logic;
signal cpu_aclr, cpu_aclr_reg : std_logic;
signal counted_value : std_logic_vector (NBIT_DATAOUT -1 downto 0 ); ----contiene il risultato del contatore associato al maintrigger
signal register_data : std_logic_vector (NBIT_DATAOUT -1 downto 0); 
signal mainout : std_logic;
signal reset_latch : std_logic;

signal bit_pattern_sbuff : std_logic_vector(3+8+NBIT_TRIG-1 downto 0);
signal serial_aclr : std_logic; -- to clear bit pattern after serial transmission
signal enable_serial_pattern_reset, serial_aclr_vetoed : std_logic;
begin

bit_pattern_sbuff(NBIT_TRIG-1 downto 0) <= bit_pattern;
bit_pattern_sbuff(10+NBIT_TRIG) <='1';
bit_pattern_sbuff(9+NBIT_TRIG) <='0';
bit_pattern_sbuff(8+NBIT_TRIG) <='1';
bit_pattern_sbuff(7+NBIT_TRIG downto NBIT_TRIG) <= std_logic_vector(to_unsigned(NBIT_TRIG,8));


------istantiate Flip Flop:
	FF: for i in NBIT_TRIG - 1 downto 0 generate 
	flipflop: trigger_ff
	port map  ( 
--			aclr => cpu_aclr or RST, -- per VME
			aclr => cpu_aclr or serial_aclr_vetoed or RST, -- per FAIR
				enable => mainout,
				data => '1',
				clock => trig_delayed(i),
				q => bit_pattern(i)
			); 
	end generate ff;
---------------------------

------istantiate Flip Flop:
	FF_MEM: for i in NBIT_TRIG - 1 downto 0 generate 
	flipflop_latch: trigger_ff
	port map  ( 
			aclr => cpu_aclr_reg or RST,
				enable => '1',
				data => bit_pattern(i),
				clock => not mainout,
				q => bit_pattern_register(i)
			); 
	end generate ff_mem;
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
     
    serial_aclr_vetoed <= serial_aclr AND enable_serial_pattern_reset;

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
				enable_serial_pattern_reset <= '1';
			elsif rising_edge(clk)then
				if((to_integer(unsigned(address)) = (base_addr))AND N_RD ='1' AND USR_ACCESS = '1') then	----loop per reperire il pattern
					data_out( NBIT_TRIG-1 downto 0) <= bit_pattern_register;
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +2))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out <= register_data;
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +4))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_TRIG-1 downto 0) <= trig_mask;
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +6))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_TRIG-1 downto 1) <= (others => '0');
					data_out(0) <= enable_serial_pattern_reset;
					selector <='1';
				else 
					selector <='0';
				end if;
				
				cpu_aclr <= '0';	
				cpu_aclr_reg <= '0';	
				
				if((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1' AND USR_ACCESS = '1') then    ----loop per azzerare i flip flop
					cpu_aclr_reg <= '1';
					
				elsif((to_integer(unsigned(address)) = (base_addr + 2))AND N_WR ='1' AND USR_ACCESS = '1') then
					register_data <= data_in;
					
				elsif((to_integer(unsigned(address)) = (base_addr + 4))AND N_WR ='1' AND USR_ACCESS = '1') then
					trig_mask <= data_in(NBIT_TRIG-1 downto 0);
					
				elsif((to_integer(unsigned(address)) = (base_addr + 6))AND N_WR ='1' AND USR_ACCESS = '1') then
					enable_serial_pattern_reset <= data_in(0); -- set to 1 to auto reset bit pattern after serial tx
					
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
