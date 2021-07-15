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
-- $Id: V2495.vhd,v 1.2 2019/05/14 08:59:14 bini Exp $ 
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
 
component debouncer
  port (
    input  : in  std_logic;             -- ingresso
    clk    : in  std_logic;             -- clock
	 rst	  : in std_logic;
    output : out std_logic);

end component;
 
component counter16
	port(
         reset    : in std_logic;
         clock_in : in std_logic;
         value_out : out std_logic_vector(NBIT_DATAout-1 downto 0)
         );

end component; 


component ID_OUT_MANAGER 
	PORT(
		ID_IN:in std_logic_vector(2 downto 0);
		DATA_IN:in std_logic_vector(31 downto 0);
		SELECT_OUT:out std_logic;
		nEnable_OUT:out std_logic;
		DATA_OUT:out std_logic_vector(31 downto 0)
	);
END component;

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

component Logic_Matrix
    generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(SUBTRG_I : in std_logic_vector(127 downto 0);
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 MTRG_O: out STD_LOGIC_VECTOR((NBIT_MTRIG*NSERIES_MTRIG-1) downto 0);
		 BITPATT: out STD_LOGIC_VECTOR(31 downto 0);
		 
		  DEBUG_BUS : out STD_LOGIC_VECTOR(31 downto 0); --for NIM output
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 VETO : in STD_LOGIC;
		  CNTRL_REG : OUT STD_LOGIC_VECTOR(15 downto 0);
		 CHC_TOT : IN STD_LOGIC_VECTOR(7 downto 0);
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
end component;



signal subtrg_debounced : std_logic_vector(127 downto 0);
signal bit_pattern : std_logic_vector(31 downto 0); 


signal ctrl_reg: std_logic_vector(15 downto 0);
signal CHC_D:std_logic_vECTOr(7 downto 0);
signal CHC_E:std_logic_vECTOr(7 downto 0);
signal CHC_TOT:std_logic_vECTOr(7 downto 0);


signal veto_in   : std_logic; -- connects GIN(0) to TriggerBox veto
signal reset        :  std_logic;
signal subtrg_pattern: std_logic_vector(127 downto 0);
signal D_int: std_LOGIC_VECTOR(31 downto 0);
signal E_int: std_LOGIC_VECTOR(31 downto 0);

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
type led_cnt_array is array(0 to (NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1) )of std_logic_vector(NBIT_DATAOUT-1 downto 0); 
signal led_cnt : led_cnt_array;
signal reset_led_cnt: std_logic_vector (NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto 0);
signal light: std_logic_vector (NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto 0);
                
signal out_F_bus: std_logic_vector(31 downto 0);					 

for all: debouncer use entity
         work.debouncer(RTL2);
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
			NIMTTL => ctrl_reg(10),
			CHC=>CHC_E,
			DATA_OUT => E_int
		);
		

 ID_F:ID_OUT_MANAGER 
	PORT map(
		ID_IN=> IDF,
		DATA_IN=>OUT_F_bus,
		SELECT_OUT => SELF,
		nEnable_OUT=>nOEF,
		DATA_OUT =>F
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

		
--debouncer on all input signals
many_db : for I in 0 to NBIT_SUBTRIG-1 generate	
	db: debouncer
		port map(
			input=>subtrg_pattern(i),
			clk=>clk,
			rst=>reset,
			output=>subtrg_debounced(i)
			);
end generate many_db;	

     --logic matrix
   LM:Logic_Matrix
		generic map(base_addr=>INFNFI2_TBOX_LMINPUT)
		port map(
		 SUBTRG_I=>subtrg_debounced,
		-- TRG_O=>bit_pattern(NBIT_TRIG-1 downto 0),
		 --MTRG_O=>bit_pattern(NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto NBIT_TRIG),
		 BitPatt=> bit_pattern,
		 DEBUG_BUS=> OUT_F_bus, --for NIM output
		 CLK=>CLK,
		 RST => reset,
		 VETO => veto_in,
		 CNTRL_REG =>ctrl_reg,
		 CHC_TOT => CHC_TOT,
		 ----------------------------BUS
		 address => REG_ADDR,
		 data_in => REG_DIN,
		 data_out => REG_DOUT,
		 n_rd => REG_RDEN,
		 n_wr => REG_WREN, 	
		 USR_ACCESS => USR_ACCESS
		 ------------------------------
		 );

	process(bit_pattern)
	begin
		C<=bit_pattern;		
	end process;
		
--led management
many_cnt: for i in NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto 0 generate
conta_led : counter16
		port map(
			clock_in => CLK and light(i),
			reset => reset_led_cnt(i),
			value_out => led_cnt(i)
		);
end generate many_cnt;


gen_led :process(bit_pattern,reset,reset_led_cnt)
 
	begin
      many_bit: for i in NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto 0 loop
	        if (reset = '1' OR reset_led_cnt(i) = '1')then
				light(i) <= '0';
			elsif rising_edge(bit_pattern(i)) then
				light(i) <= '1';
			end if;
      end loop;
	end process;

 
	cnt_irq :process(CLK,reset)
	begin
	     many_bit: for i in NBIT_TRIG+NBIT_MTRIG*NSERIES_MTRIG-1 downto 0 loop
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
    
   
   
   
   nINT <= '1';
     
--     GOUT(0) <= veto_tbox;

    --GOUT(0) <= veto_tbox   when veto_selection = '1' else 'Z';
    nOEG <= '1';  -- general pins used as inputs
    veto_in <= not GIN(0);    
    

    
    --disabled secundary output
    --SELF <= 'Z';
    --nOEF <= 'Z';
    --F(31 downto 8)    <= (others => 'Z');
    
    
    LED <= light(7 downto 0);

   
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
            REG_DOUT  => REG_DOUT,
            USR_ACCESS  => USR_ACCESS
  
        );
        

end rtl;
   
