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
		 MTRG_O: out STD_LOGIC_VECTOR((NBIT_MTRIG*NSERIES_MTRIG-1) downto 0);
		 DEBUG_BUS : out STD_LOGIC_VECTOR(7 downto 0); --for NIM output
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 VETO : in STD_LOGIC;
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

component  SingleChannelGate 
	--generic(counter: integer:= 0);
	port(
		reset    : in std_logic;
      clk : in std_logic;
      input :in std_logic;
		window_len : in std_logic_vector(16 downto 0);
		output: out std_logic
     );
end component;	
	
component bit_count 
  port (
    bit_in    : in  std_logic_vector(NBIT_SUBTRIG-1 downto 0);  -- bits to be counted
    clk       : in  std_logic;          -- clock signal
	 rst       : in std_logic;
    mult      : out  std_logic_vector(7 downto 0);  -- majority logic outputs  mult[0]=1 if at least 1 input true, etc.
	 dout : out  STD_uLOGIC_vector(7 downto 0);
    VETO      : in STD_LOGIC            -- general VETO: trigger ok only if veto=0
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
	
-- ctrl_register(3 downto 0): controls debug mux output
--ctrl_register(12 downto 11) : subset for trigger LA
signal ctrl_register : std_logic_vector(15 downto 0); 
signal debug_signal : STD_LOGIC_VECTOR(NBIT_DEBUG-1 downto 0);
signal GATED_SUBTRG_I : std_logic_vector(NBIT_SUBTRIG - 1 downto 0);

signal SUBTRG_I_extended : STD_LOGIC_VECTOR(127 downto 0);
signal GATED_SUBTRG_I_extended : STD_LOGIC_VECTOR(127 downto 0);

--data bus for multiplexers
signal LA_DATAOUT : STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
signal LA_selector : STD_LOGIC;
signal LM_DATAOUT : STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
signal LM_selector : STD_LOGIC;

signal TRG_O_int:std_logic_vector(NBIT_TRIG-1 downto 0);
signal MTRG_O_int:std_logic_vector(NSERIES_MTRIG*NBIT_MTRIG-1 downto 0);
signal compare_to : std_logic_vector(NBIT_SUBTRIG - 1 downto 0);

signal reset :std_logic;

--maschera per gli or
--type mask_for_or is array (0 to NBIT_TRIG-1) of std_logic_vector(NBIT_SUBTRIG-1 downto 0);
--signal or_lm_data : mask_for_or;

signal or_lm_data : std_logic_vector(NBIT_TRIG*NBIT_SUBTRIG-1 downto 0);

type masked_or_inputs is array (0 to NBIT_TRIG-1) of std_LOGIC_VECTOR (NBIT_SUBTRIG-1 downto 0);
signal masked_inp : masked_or_inputs;

--maschera di molteplicit
signal multi_lm_data : std_logic_vector(NSERIES_MTRIG*NBIT_SUBTRIG-1 downto 0);

type masked_multi_inputs is array (0 to NSERIES_MTRIG-1)of std_logic_vector (NBIT_SUBTRIG-1 downto 0);
signal multi_masked_inp : masked_multi_inputs;

type multi_triggers is array (0 to NSERIES_MTRIG-1) of std_LOGIC_VECTOR (NBIT_MTRIG-1 downto 0);
signal Mtriggers : multi_triggers;
signal mult_window : std_logic_vector(16 downto 0);
	
BEGIN 
	selector<=LM_Selector or LA_Selector;
	TRG_O<=TRG_O_int;
	MTRG_O<=MTRG_O_int;
	DEBUG_BUS<=debug_signal(7 downto 0);
	mult_window(16)<='0';
	OUTPUT_MUX:process(LA_selector,LM_selector,LA_DATAOUT,LM_DATAOUT)
	BEGIN
		if(LM_Selector='1') then
			DATa_out<=LM_DATAOUT;
		elsif(LA_selector='1') then
			DATa_out<=LA_DATAOUT;
		else
			DATa_out<=(others=>'0');
		end if;
	end process OUTPUT_MUX;
	
	Extender:process(SUBTRG_I,GATED_SUBTRG_I)
	begin
		SUBTRG_I_extended(NBIT_SUBTRIG-1 downto 0)<=SUBTRG_I;
		SUBTRG_I_extended(127 downto NBIT_SUBTRIG)<=(others=>'0');
		GATED_SUBTRG_I_extended(NBIT_SUBTRIG-1 downto 0)<=GATED_SUBTRG_I;
		GATED_SUBTRG_I_extended(127 downto NBIT_SUBTRIG)<=(others=>'0');		
	end process Extender;
	
	compare_to <= (others => '0');
	
	--gates for multiplicity
	gates:for I in 0 to NBIT_SUBTRIG-1 generate
		gate_1ch:SingleChannelGate
			port map(
				reset    =>rst,
				clk =>clk,
				input =>SUBTRG_I(i),
				window_len => mult_window,
				output =>GATED_SUBTRG_I(i)
		);
	end generate gates;
	
	
	
	
	--building of or triggers
	process(or_lm_data,masked_inp,compare_to,veto,SUBTRG_I)
	begin
		or_trg: for I in 0 to NBIT_TRIG-1 loop
			masked_inp(i)<=SUBTRG_I and or_lm_data(NBIT_SUBTRIG*(i+1)-1 downto NBIT_SUBTRIG*i);
			if(masked_inp(i)/=compare_to and VETO='0') then
				TRG_O_int(i)<='1';
			else 
				TRG_O_int(i)<='0';
			end if;
		end loop or_trg;
	end process;
		
	--building of masked trigger sets for multiplicity
	process(multi_lm_data,masked_inp,compare_to,veto,subTRG_I)
	begin
		for I in 0 to NSERIES_MTRIG-1 loop
			multi_masked_inp(i)<=GATED_SUBTRG_I and multi_lm_data(NBIT_SUBTRIG*(i+1)-1 downto NBIT_SUBTRIG*i);
		end loop;
	end process;
			
	--building the multiplicity trigger
	multigen : for I in 0 to NSERIES_MTRIG-1 generate
			bc : bit_count
			port map(
				bit_in=>multi_masked_inp(i),
				clk=>CLK,
				RST=>RST,
				mult=>Mtriggers(i),
				VETO=>'0'
			);
		end generate multigen;
		
	process(Mtriggers)
	begin		
		for I in 0 to NSERIES_MTRIG-1 loop
				MTRG_O_int(8*i+7 downto 8*i)<=Mtriggers(i);
		end loop;		
	end process;
	
	
	------------- Instantiate Logic Analyzer
	Logic_Analyzer_1: Logic_Analyzer
		generic map(base_addr => x"4000")
		port map(
				 INPUT => debug_signal,
				 EXT_TRIGGER=> '0',
			 CLK => CLK,
				 RST => rst,
				 address => address,
				 data_in =>data_in,
				 data_out => LA_DATAOUT,
				 n_rd => n_rd,
				 n_wr => n_wr,
				 USR_ACCESS => USR_ACCESS,
				 selector => LA_selector		);
	
	
	
	registers: process(clk,rst)
	begin
		if (RST = '1')then
	    		-----Reset dei vari array di memorizzazione
				mult_window(15 downto 3) <=(others=>'0');
				mult_window(2 downto 0) <="100";
				ctrl_register<=(others=>'0');
				LM_selector <='0';
--				input256_matcher <= ( 35 downto 34 => "01", 1 downto 0 => "10", others =>"00");
--				input8_matcher <= (0 => "10", 1 => "01" , others => "00");
-- mettiamo dei default piu professionali! gab 2010-4-26
				or_lm_data <= (others=> '0');
				multi_lm_data<= (others=> '0');
				
			elsif rising_edge(clk)then
				LM_DATAOUT <=(others=>'0');
				LM_selector <='0';
				----Decodifica dell'indirizzo:
				--memoria principale della LM 0x1900 byte ovvero 6400 (1600 registri)
				--Completely changed data storage to extend to 128 inputs
				
				read_AND_WRITE_ORDATA: for i in 0 TO NPOS_LM-1 loop			-----Da 0 a 255 scrive o legge sull'or_lm_data a gruppi di 16 elementi per volta
						if((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_RD ='1'  -- it was 2*i in V1495
			                 AND USR_ACCESS = '1') then		
								  read_many: for j in 0 to 15 loop
								      IF(16*I+J<NBIT_SUBTRIG*NBIT_TRIG)THEN
											LM_dataout(j) <= or_lm_data(16*i+j);
										END IF;
									end loop;
								LM_selector <='1';
						ELSIF ((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_WR ='1'  -- it was 2*i in V1495
			                 AND USR_ACCESS = '1')THEN
								  write_many: for j in 0 to 15 loop
										IF(16*I+J<NBIT_SUBTRIG*NBIT_TRIG)THEN
											or_lm_data(16*I+j) <= DATA_IN(j);
										end if;
									end loop;
						END IF;
					end loop;
					
					--Added for R/W of registers with the multiplicity mask
					read_AND_WRITEMULT: for i in 0 TO NPOS_MULT-1 loop			-----Scrive la maschera di molteplicit a  16 bit alla volta
						if((to_integer(unsigned(address)) = (base_addr + 7936 + 2*i))AND N_RD ='1'  -- it was 2*i in V1495
			                 AND USR_ACCESS = '1') then		
								  read_many: for j in 0 to 15 loop
								      IF(16*I+J<NBIT_SUBTRIG*NSERIES_MTRIG)THEN
											LM_dataout(j) <= multi_lm_data(16*i+j);
										END IF;
									end loop;
								LM_selector <='1';
						ELSIF ((to_integer(unsigned(address)) = (base_addr+7936+ 2*i))AND N_WR ='1'  -- it was 2*i in V1495
			                 AND USR_ACCESS = '1')THEN
								  write_many: for j in 0 to 15 loop
										IF(16*I+J<NBIT_SUBTRIG*NSERIES_MTRIG)THEN
											multi_lm_data(16*I+j) <= DATA_IN(j);
										end if;
									end loop;
						END IF;
					end loop;
					
					if( address = INFNFI_BOARDMODEL AND N_RD ='1' AND USR_ACCESS = '1') then
						LM_dataout(15 downto 0) <= X"05D7";
						LM_selector<='1';
					end if;
					if( address = INFNFI_BOARDDATA AND N_RD ='1' AND USR_ACCESS = '1') then
						LM_dataout(1 downto 0) <= "01";
						LM_dataout(3 downto 2) <= "00"+NSERIES_MTRIG;
						LM_dataout(10 downto 4) <= "0000000"+NBIT_SUBTRIG;
						LM_dataout(15 downto 11) <= "00000"+NBIT_TRIG;
						LM_selector<='1';
					end if;
					if((to_integer(unsigned(address)) = (INFNFI_CTRL))AND N_RD ='1' AND USR_ACCESS = '1') then
						LM_selector <='1';
--						data_out_tbox(7 downto 0) <= ctrl_register;
						LM_dataout<= ctrl_register;
					end if;	
					if((to_integer(unsigned(address)) = (INFNFI_CTRL))AND N_WR ='1' AND USR_ACCESS = '1') then  
-- 						ctrl_register <= data_in(7 downto 0);
						ctrl_register <= data_in;
					end if;	
					-- resolving time window	
					if((address = x"1200" )AND N_RD ='1' AND USR_ACCESS = '1') then	
						LM_selector <='1';
						LM_dataout <= mult_window(15 downto 0);
					end if;	
					if(address=x"1200" AND N_WR ='1'AND USR_ACCESS = '1') then	
						mult_window(15 downto 0) <= data_in;
					end if;				
		end if;	

	end process registers;

	debug_mux:PROCESS(RST,CLK,ctrl_register,subtrg_i_extended,MTRG_O_int,TRG_O_int)
BEGIN
	debug_signal <= (others =>'0');
	if(ctrl_register(3 downto 0) = X"1") then
		case (ctrl_register (12 downto 11)) is
			when "00"=>
				debug_signal <= subtrg_i_extended(NBIT_DEBUG-1 downto 0);
			when "01"=>
				debug_signal <= subtrg_i_extended(2*NBIT_DEBUG-1 downto NBIT_DEBUG);
			when "10"=>
				debug_signal <= subtrg_i_extended(3*NBIT_DEBUG-1 downto 2*NBIT_DEBUG);
			when "11"=>
				debug_signal <= subtrg_i_extended(4*NBIT_DEBUG-1 downto 3*NBIT_DEBUG);
		end case;
	elsif(ctrl_register(3 downto 0) = X"2") then
		case (ctrl_register (12 downto 11)) is
			when "00"=>
				debug_signal <= gated_subtrg_i_extended(NBIT_DEBUG-1 downto 0);
			when "01"=>
				debug_signal <= gated_subtrg_i_extended(2*NBIT_DEBUG-1 downto NBIT_DEBUG);
			when "10"=>
				debug_signal <= gated_subtrg_i_extended(3*NBIT_DEBUG-1 downto 2*NBIT_DEBUG);
			when "11"=>
				debug_signal <= gated_subtrg_i_extended(4*NBIT_DEBUG-1 downto 3*NBIT_DEBUG);
		end case;
	elsif(ctrl_register(3 downto 0) = X"3") then
		debug_signal(NBIT_TRIG-1 downto 0) <= TRG_O_int;
		debug_signal(NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto NBIT_TRIG) <= MTRG_O_int;
	elsif(ctrl_register(3 downto 0) = X"F") then
		debug_signal <= (others =>'1');
	end if;
END PROCESS debug_mux;

	
end Behavioral;
