-- V2495.vhd
-- -----------------------------------------------------------------------
-- V2495 User Template (top level)
-- -----------------------------------------------------------------------
--  Date        : 08/06/2016
--  Contact     : support.nuclear@caen.it
-- (c) CAEN SpA - http://www.caen.it   
-- -----------------------------------------------------------------------
--
--                   
--------------------------------------------------------------------------------
-- $Id: V2495.vhd,v 1.2 2021/07/12 14:51:54 bini Exp $ 
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    use work.V2495_pkg.all;
    
USE work.v1495pkg.all;
use work.T_SConstants.all;

-- ----------------------------------------------
entity V2495 is
-- ----------------------------------------------
    port (

        CLK    : in     std_logic;                         -- System clock 
                                                           -- (50 MHz)

    -- ------------------------------------------------------
    -- Mainboard I/O ports
    -- ------------------------------------------------------   
      -- Port A : 32-bit LVDS/ECL input
         A        : in    std_logic_vector (31 DOWNTO 0);  -- Data bus 
      -- Port B : 32-bit LVDS/ECL input                    
         B        : in    std_logic_vector (31 DOWNTO 0);  -- Data bus
      -- Port C : 32-bit LVDS output                       
         C        : out   std_logic_vector (31 DOWNTO 0);  -- Data bus
      -- Port G : 2 NIM/TTL input/output                   
         GIN      : in    std_logic_vector ( 1 DOWNTO 0);  -- In data
         GOUT     : out   std_logic_vector ( 1 DOWNTO 0);  -- Out data
         SELG     : out   std_logic;                       -- Level select
         nOEG     : out   std_logic;                       -- Output Enable

    -- ------------------------------------------------------
    -- Expansion slots
    -- ------------------------------------------------------                                                                  
      -- PORT D Expansion control signals                  
         IDD      : in    std_logic_vector ( 2 DOWNTO 0);  -- Card ID
         SELD     : out   std_logic;                       -- Level select
         nOED     : out   std_logic;                       -- Output Enable
         D        : inout std_logic_vector (31 DOWNTO 0);  -- Data bus
                                                           
      -- PORT E Expansion control signals                  
         IDE      : in    std_logic_vector ( 2 DOWNTO 0);  -- Card ID
         SELE     : out   std_logic;                       -- Level select
         nOEE     : out   std_logic;                       -- Output Enable
         E        : inout std_logic_vector (31 DOWNTO 0);  -- Data bus
                                                           
      -- PORT F Expansion control signals                  
         IDF      : in    std_logic_vector ( 2 DOWNTO 0);  -- Card ID
         SELF     : out   std_logic;                       -- Level select
         nOEF     : out   std_logic;                       -- Output Enable
         F        : inout std_logic_vector (31 DOWNTO 0);  -- Data bus

    -- ------------------------------------------------------
    -- Gate & Delay
    -- ------------------------------------------------------
      --G&D I/O
        GD_START   : out  std_logic_vector(31 downto 0);   -- Start of G&D
        GD_DELAYED : in   std_logic_vector(31 downto 0);   -- G&D Output
      --G&D SPI bus                                        
        SPI_MISO   : in   std_logic;                       -- SPI data in
        SPI_SCLK   : out  std_logic;                       -- SPI clock
        SPI_CS     : out  std_logic;                       -- SPI chip sel.
        SPI_MOSI   : out  std_logic;                       -- SPI data out
      
    -- ------------------------------------------------------
    -- LED
    -- ------------------------------------------------------
        LED        : out std_logic_vector(7 downto 0);     -- User led    
    
    -- ------------------------------------------------------
    -- Local Bus in/out signals
    -- ------------------------------------------------------
      -- Communication interface
        nLBRES     : in     std_logic;                     -- Bus reset
        nBLAST     : in     std_logic;                     -- Last cycle
        WnR        : in     std_logic;                     -- Read (0)/Write(1)
        nADS       : in     std_logic;                     -- Address strobe
        nREADY     : out    std_logic;                     -- Ready (active low) 
        LAD        : inout  std_logic_vector (15 DOWNTO 0);-- Address/Data bus
      -- Interrupt requests  
        nINT       : out    std_logic                      -- Interrupt request
  );
end V2495;

-- ---------------------------------------------------------------
architecture rtl of V2495 is
-- ---------------------------------------------------------------


-- component Trigger Box
component trigger_box is
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
    Port ( 
		CLK : in STD_LOGIC;
		RST: in STD_LOGIC;
		SUBTRG_INPUT_32 : in STD_LOGIC_VECTOR(NBIT_SUBTRIG-1 downto 0);
--		TRG_INPUT_8: in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0);
		DEBUG_OUTPUT : out STD_LOGIC_VECTOR(NBIT_DEBUG-1 downto 0);
		MAINTRG : out  STD_LOGIC;
		RES_TIME : out  STD_LOGIC;
--		VETO_SIGNAL : in STD_LOGIC;
		VETO_OUTPUT : out STD_LOGIC; -- VETO OUT WHEN VETO IS INTERNALLY GENERATED AND EMITTED FROM CONNECTOR G,
		VETO_INPUT  : in STD_LOGIC; -- VETO IN IF WE USE EXTERNAL VETO
		VETO_REG : out std_logic;
		VETO_SEL : out STD_LOGIC; -- this is bit 8 of ctrl_register (if 1 we use internally generated VETO, if 0 we use signal at GIN(0))
		trigcodebit : out std_logic;
		IRQ_ENA : out STD_LOGIC; -- this is bit 9 of ctrl_register (if 1 we use enable IRQ, otherwise we tristate nINT
		PATTERN : OUT STD_LOGIC_VECTOR(NBIT_TRIG -1 downto 0);
		PATTERN_SERIAL : OUT STD_LOGIC;
		INT : OUT STD_LOGIC;  -- interrupt request signal
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
 end component;
 
component counter16
	port(
         reset    : in std_logic;
         clock_in : in std_logic;
         value_out : out std_logic_vector(NBIT_DATAout-1 downto 0)
         );

end component; 

component ID_MANAGER 
	PORT(
		ID_IN:in std_logic_vector(2 downto 0);
		DATA_IN:inout std_logic_vector(31 downto 0);
		SELECT_OUT:out std_logic;
		nEnable_OUT:out std_logic;
		NIMTTL:in STD_logic;
		CHC:out std_logic_vector(7 downto 0);
		DATA_OUT:out std_logic_vector(31 downto 0)
	);
END component;

component SUBTRG_MERGER
	port(
		IN_A:in std_logic_vector(31 downto 0);
		IN_B:in std_logic_vector(31 downto 0);
		IN_D:in std_logic_vector(31 downto 0);
		CHC_D:in std_logic_vector(7 downto 0);
		IN_E:in std_logic_vector(31 downto 0);
		CHC_E:in std_logic_vector(7 downto 0);
		OUT_SUBTRG:out std_logic_vector(127 downto 0);
		CHC_TOT:out std_logic_vector(7 downto 0)		
	);
END component;

component ID_OUT_MANAGER 
	PORT(
		ID_IN:in std_logic_vector(2 downto 0);
		DATA_IN:in std_logic_vector(31 downto 0);
		SELECT_IN: in std_logic;
		SELECT_OUT:out std_logic;
		nEnable_OUT:out std_logic;
		DATA_OUT:inout std_logic_vector(31 downto 0)
	);
END component;

signal ctrl_reg: std_logic_vector(15 downto 0);
signal CHC_D:std_logic_vECTOr(7 downto 0);
signal CHC_E:std_logic_vECTOr(7 downto 0);
signal CHC_TOT:std_logic_vECTOr(7 downto 0);
signal debug_int: std_logic_vector(NBIT_DEBUG-1 downto 0);
signal main_int: std_logic_vector(31 downto 0);
signal veto_tbox   : std_logic; -- connects TriggerBox veto to G_DOUT(0)
signal veto_in   : std_logic; -- connects GIN(0) to TriggerBox veto
signal veto_selection   : std_logic;
signal veto_reg: std_logic;
signal irq_enable   : std_logic;
signal REG_DOUT_TBOX  : std_logic_vector (15 DOWNTO 0);
signal bit_pattern : std_logic_vector(NBIT_TRIG-1 downto 0); 
signal serial_pattern : std_logic;
signal validation : std_logic;
signal trigger : std_logic;
signal reset        :  std_logic;
signal int_qui        :  std_logic;
signal subtrg_pattern: std_logic_vector(127 downto 0);
signal D_int: std_LOGIC_VECTOR(31 downto 0);
signal E_int: std_LOGIC_VECTOR(31 downto 0);
signal F_int: std_logic_vector(31 downto 0);
signal trigcode_bit : std_logic;
      --*************************************************
      -- REGISTER INTERFACE
      --*************************************************
signal REG_WREN    :    std_logic;                       -- Write pulse (active high)
signal REG_RDEN    :    std_logic;                       -- Read  pulse (active high)
signal REG_ADDR    :    std_logic_vector (15 DOWNTO 0);  -- Register address
signal REG_DIN     :    std_logic_vector (15 DOWNTO 0);  -- Data from CAEN Local Bus
signal REG_DOUT    :    std_logic_vector (15 DOWNTO 0);  -- Data to   CAEN Local Bus
signal USR_ACCESS  :    std_logic;                       -- Current register access is 
                                                        -- at user address space(Active high)
type led_cnt_array is array(0 to (NBIT_TRIG-1) )of std_logic_vector(NBIT_DATAOUT-1 downto 0); 
signal led_cnt : led_cnt_array;
signal reset_led_cnt: std_logic_vector (NBIT_TRIG-1 downto 0);
signal light: std_logic_vector (NBIT_TRIG-1 downto 0);
signal LEDVETO: std_logic_vector(7 downto 0);
                                                           

-----\
begin --
-----/
 
 ID_D:ID_MANAGER
		port map(
			ID_IN => IDD,
			DATA_IN => D,
			SELECT_OUT => SELD,
			nEnable_OUT => nOED,
			NIMTTL => ctrl_reg(10),
			CHC=>CHC_D,
			DATA_OUT => D_int
		);
		
  
 ID_E:ID_MANAGER
		port map(
			ID_IN => IDE,
			DATA_IN => E,
			SELECT_OUT => SELE,
			nEnable_OUT => nOEE,
			NIMTTL=>ctrl_reg(10),
			CHC=>CHC_E,
			DATA_OUT => E_int
		);

 input_merger:SUBTRG_MERGER
		port map(
			IN_A => A,
			IN_B => B,
			IN_D => D_int,
			CHC_D =>CHC_D,
			IN_E => E_int,
			CHC_E => CHC_E,
			OUT_SUBTRG => subtrg_pattern,
			CHC_TOT=> CHC_TOT
		);




	tbox: trigger_box
		generic map(base_addr=>INFNFI2_TBOX_CTRL)
		port map(
			CLK => CLK,
			RST => reset,
			MAINTRG => validation,  
			RES_TIME => trigger,  
--			VETO_SIGNAL =>not G_DIN(0),  -- NIM input seems positive logic!!
			VETO_OUTPUT => veto_tbox,  -- used when G connector allows for VETO monitoring
			VETO_INPUT => veto_in,  -- used when G connector as VETO input
			VETO_SEL => veto_selection,  -- used when G connector as VETO input
			VETO_REG => veto_Reg,
			trigcodebit => trigcode_bit,
			IRQ_ENA => irq_enable,  
			DEBUG_OUTPUT =>debug_int,
			SUBTRG_INPUT_32 =>subtrg_pattern(NBIT_SUBTRIG-1 downto 0),
			PATTERN => bit_pattern,
			PATTERN_SERIAL => serial_pattern,
			INT => int_qui, -- interrupt request signal
			CNTRL_REG => ctrl_reg, --ctrl register
			CHC_TOT =>CHC_TOT,
-- ============================ 
			address => REG_ADDR,
			data_in => REG_DIN,
			data_out => REG_DOUT_TBOX,
			n_rd => REG_RDEN,
			n_wr => REG_WREN, 	
			USR_ACCESS => USR_ACCESS
-- 			selector => selector1 
			);
			
		



many_cnt: for i in NBIT_TRIG-1 downto 0 generate
conta_led : counter16
		port map(
			clock_in => CLK and light(i),
			reset => reset_led_cnt(i),
			value_out => led_cnt(i)
		);
end generate many_cnt;
gen_led :process(bit_pattern,reset,reset_led_cnt)
 
	begin
      many_bit: for i in NBIT_TRIG-1 downto 0 loop
	        if (reset = '1' OR reset_led_cnt(i) = '1')then
				light(i) <= '0';
			elsif rising_edge(bit_pattern(i)) then
				light(i) <= '1';
			end if;
      end loop;
	end process;

 
	cnt_irq :process(CLK,reset)
	begin
	     many_bit: for i in NBIT_TRIG-1 downto 0 loop
			if (reset = '1')then
				reset_led_cnt(i) <= '0';
			elsif rising_edge(CLK) then
				reset_led_cnt(i) <= '0';
				if(light(i) = '1' AND led_cnt(i) >= X"2000") then  
					reset_led_cnt(i) <= '1';
				end if;
			end if;
         end loop;
	end process;
    -- Unused output ports are explicitally set to HiZ
    -- ----------------------------------------------------
    
  nINT <= not int_qui when irq_enable = '1' else '1';
     
--     GOUT(0) <= veto_tbox;

    GOUT(0) <= veto_tbox   when veto_selection = '1' else 'Z';
    nOEG <= not veto_selection;  -- when VETO_SEL is '1' we use G(0) as output
    SELG<='1';
    veto_in <= GIN(0) or GIN(1);    
    
--    GOUT <= (others => 'Z');

 --   SELD <= 'Z';
 --   nOED <= 'Z';
 --   D    <= (others => 'Z');
    
 --   SELE <= 'Z';
 --   nOEE <= 'Z';
 --   E    <= (others => 'Z');
    
    
   -- SELF <= '1';
   -- nOEF <= '0';
    -- F    <= (others => 'Z');
    main_int(NBIT_TRIG -1 downto 0) <= bit_pattern; -- BitPattern output are LSBits of F port
	 main_int(27 downto NBIT_TRIG)<=(others=>'0');
	main_int(31) <= validation;  -- MainTrigger output is channel 31 on F port
	main_int(30) <= trigger;
	main_int(29) <= serial_pattern;
	main_int(28) <= trigcode_bit;
	process(main_int,debug_int,ctrl_reg)
	begin
		if(ctrl_reg(4)='0') then
			C<=main_int;
			F_int(NBIT_DEBUG-1 downto 0)<=debug_int;
		else
			F_int<=main_int;
			C(NBIT_DEBUG-1 downto 0)<=debug_int;
		end if;
	end process;
	
	ID_F:ID_OUT_MANAGER 
	port map(
		ID_IN=>IDF,
		DATA_IN=>F_int,
		SELECT_IN=>ctrl_reg(13),
		SELECT_OUT=>SELF,
		nEnable_OUT=>nOEF,
		DATA_OUT=>F
	);

	LEDVETO(3 downto 0)<=(others=>veto_in);
	LEDVETO(7 downto 4)<=(others=>veto_reg);
	
    LED <= light(NBIT_TRIG-1 downto 0) or LEDVETO;

   
    reset <= not(nLBRES);
           
    -- --------------------------
    --  Local Bus slave interface
    -- --------------------------  
    I_LBUS_INTERFACE: entity work.lb_int  
        port map (
            clk         => CLK,   
            reset       => reset,
            -- Local Bus            
            nBLAST      => nBLAST,   
            WnR         => WnR,      
            nADS        => nADS,     
            nREADY      => nREADY,   
            LAD         => LAD,

            REG_WREN   => REG_WREN,
            REG_RDEN  => REG_RDEN,
            REG_ADDR  => REG_ADDR,
            REG_DIN   => REG_DIN,
            REG_DOUT  => REG_DOUT_TBOX,
            USR_ACCESS  => USR_ACCESS
  
        );
        

end rtl;
   
