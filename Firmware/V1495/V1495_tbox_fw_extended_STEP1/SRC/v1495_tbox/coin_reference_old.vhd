-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: V1495_TBOX
-- Device:          ALTERA EP1C4F400C6
-- Author:          Luca Colombini (l.colombini@caen.it)
-- Date:            02-03-2006
-- ----------------------------------------------------------------------------
-- Module:          COIN_REFERENCE
-- Description:     Reference design to use the V1495 board 
--                  as a Coincidence Unit & I/O Register. 
--                  A gate pulse is generated on G port when a data 
--                  patterns on input ports A and B satisfy a trigger condition.
--                  The trigger condition implemented in this reference design
--                  is true when a bit-per-bit logic operation on port A and B 
--                  is true. The logic operator applied to Port A and B is
--                  selectable by means of a register bit (MODE Register Bit 4).
--                  If MODE bit 4 is set to '0', an AND logic operation is applied
--                  to corresponding bits in Port A and B.
--                  (i.e. A(0) AND B(0), A(1) AND B(1) etc.). 
--                  In this case, a trigger is generated if corresponding A and B
--                  port bits are '1' at the same time.
--                  If MODE bit 4 is set to '1', an OR logic operation is applied
--                  to corresponding bits in Port A and B.
--                  (i.e. A(0) OR B(0), A(1) OR B(1) etc.)
--                  In this case, a trigger is generated if there is a '1' on one
--                  bit of either port A or B.
--                  Port A and B bits can be singularly masked through a register,
--                  so that a '1' on that bit doesn't generate any trigger.
--                  Expansion mezzanine cards can be directly controlled through
--                  registers already implemented in this design.
--                  The expansion mezzanine is identified by a unique 
--                  identification code that can be read through a register.
-- ****************************************************************************

-- ############################################################################
-- Revision History:
--   Date         Author          Revision             Comments
--   02 Mar 06    LC              1.0                  Creation
-- ############################################################################

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- Use OR_REDUCE function

USE work.v1495pkg.all;
use work.T_SConstants.all;

ENTITY coin_reference IS
   PORT( 
      nLBRES      : IN     std_logic;                       -- Async Reset (active low)
      LCLK        : IN     std_logic;                       -- Local Bus Clock
      --*************************************************
      -- REGISTER INTERFACE
      --*************************************************
      REG_WREN    : IN     std_logic;                       -- Write pulse (active high)
      REG_RDEN    : IN     std_logic;                       -- Read  pulse (active high)
      REG_ADDR    : IN     std_logic_vector (15 DOWNTO 0);  -- Register address
      REG_DIN     : IN     std_logic_vector (15 DOWNTO 0);  -- Data from CAEN Local Bus
      REG_DOUT    : OUT    std_logic_vector (15 DOWNTO 0);  -- Data to   CAEN Local Bus
      USR_ACCESS  : IN     std_logic;                       -- Current register access is 
                                                            -- at user address space(Active high)
      --*************************************************
      -- V1495 Front Panel Ports (PORT A,B,C,G)
      --*************************************************
      A_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
      B_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL) 
      C_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- Out C (32 x LVDS)
      G_LEV       : OUT    std_logic;                       -- Output Level Select (NIM/TTL)
      G_DIR       : OUT    std_logic;                       -- Output Enable
      G_DOUT      : OUT    std_logic_vector (1 DOWNTO 0);   -- Out G - LEMO (2 x NIM/TTL)
      G_DIN       : IN     std_logic_vector (1 DOWNTO 0);   -- In G - LEMO (2 x NIM/TTL)
      --*************************************************
      -- A395x MEZZANINES INTERFACES (PORT D,E,F)
      --*************************************************
      -- Expansion Mezzanine Identifier:
      -- x_IDCODE :
      -- 000 : A395A (32 x IN LVDS/ECL)
      -- 001 : A395B (32 x OUT LVDS)
      -- 010 : A395C (32 x OUT ECL)
      -- 011 : A395D (8  x IN/OUT NIM/TTL)
      
      -- Expansion Mezzanine Port Signal Standard Select
      -- x_LEV : 
      --    0=>TTL,1=>NIM

      -- Expansion Mezzanine Port Direction
      -- x_DIR : 
      --    0=>OUT,1=>IN

      -- In/Out D (I/O Expansion)
      D_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);  -- D slot mezzanine Identifier
      D_LEV       : OUT    std_logic;                       -- D slot Port Signal Level Select 
      D_DIR       : OUT    std_logic;                       -- D slot Port Direction
      D_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- D slot Data In  Bus
      D_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- D slot Data Out Bus
      -- In/Out E (I/O Expansion)
      E_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);  -- E slot mezzanine Identifier
      E_LEV       : OUT    std_logic;                       -- E slot Port Signal Level Select
      E_DIR       : OUT    std_logic;                       -- E slot Port Direction
      E_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- E slot Data In  Bus
      E_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- E slot Data Out Bus
      -- In/Out F (I/O Expansion)
      F_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);  -- F slot mezzanine Identifier
      F_LEV       : OUT    std_logic;                       -- F slot Port Signal Level Select
      F_DIR       : OUT    std_logic;                       -- F slot Port Direction
      F_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- F slot Data In  Bus
      F_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- F slot Data Out Bus
      --*************************************************
      -- DELAY LINES
      --*************************************************
      -- PDL = Programmable Delay Lines  (Step = 0.25ns / FSR = 64ns)
      -- DLO = Delay Line Oscillator     (Half Period ~ 10 ns)
      -- 3D3428 PDL (PROGRAMMABLE DELAY LINE) CONFIGURATION
      PDL_WR      : OUT    std_logic;                       -- Write Enable
      PDL_SEL     : OUT    std_logic;                       -- PDL Selection (0=>PDL0, 1=>PDL1)
      PDL_READ    : IN     std_logic_vector ( 7 DOWNTO 0);  -- Read Data
      PDL_WRITE   : OUT    std_logic_vector ( 7 DOWNTO 0);  -- Write Data
      PDL_DIR     : OUT    std_logic;                       -- Direction (0=>Write, 1=>Read)
      -- DELAY I/O
      PDL0_OUT    : IN     std_logic;                       -- Signal from PDL0 Output
      PDL1_OUT    : IN     std_logic;                       -- Signal from PDL1 Output
      DLO0_OUT    : IN     std_logic;                       -- Signal from DLO0 Output
      DLO1_OUT    : IN     std_logic;                       -- Signal from DLO1 Output
      PDL0_IN     : OUT    std_logic;                       -- Signal to   PDL0 Input
      PDL1_IN     : OUT    std_logic;                       -- Signal to   PDL1 Input
      DLO0_GATE   : OUT    std_logic;                       -- DLO0 Gate (active high)
      DLO1_GATE   : OUT    std_logic;                       -- DLO1 Gate (active high)
      --*************************************************
      -- SPARE PORTS
      --*************************************************
      SPARE_OUT    : OUT   std_logic_vector(11 downto 0);   -- SPARE Data Out 
      SPARE_IN     : IN    std_logic_vector(11 downto 0);   -- SPARE Data In
      SPARE_DIR    : OUT   std_logic_vector(11 downto 0);   -- SPARE Direction (0 => OUT, 1 => IN)   
      --*************************************************
      -- LED
      --*************************************************
      RED_PULSE       : OUT    std_logic;                   -- RED   Led Pulse (active high)
      GREEN_PULSE     : OUT    std_logic  ;                  -- GREEN Led Pulse (active high)
      nINT        : OUT    std_logic                       -- interrupt request

   );

-- Declarations

END coin_reference ;

ARCHITECTURE rtl OF coin_reference IS

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
		VETO_SEL : out STD_LOGIC; -- this is bit 8 of ctrl_register (if 1 we use internally generated VETO, if 0 we use signal at GIN(0))
		IRQ_ENA : out STD_LOGIC; -- this is bit 9 of ctrl_register (if 1 we use enable IRQ, otherwise we tristate nINT
		PATTERN : OUT STD_LOGIC_VECTOR(NBIT_TRIG -1 downto 0);
		PATTERN_SERIAL : OUT STD_LOGIC;
		INT : OUT STD_LOGIC;  -- interrupt request signal
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
 end component;
 
component counter16
	port(
         reset    : in std_logic;
         clock_in : in std_logic;
         value_out : out std_logic_vector(NBIT_DATAout-1 downto 0)
         );

end component; 


-- Registers
signal A_STATUS   : std_logic_vector(31 downto 0); -- R
signal B_STATUS   : std_logic_vector(31 downto 0); -- R
signal C_STATUS   : std_logic_vector(31 downto 0); -- R
signal A_MASK     : std_logic_vector(31 downto 0); -- W
signal B_MASK     : std_logic_vector(31 downto 0); -- W
signal C_MASK     : std_logic_vector(31 downto 0); -- W
signal GATEWIDTH  : std_logic_vector(15 downto 0); -- W
signal C_CONTROL  : std_logic_vector(31 downto 0); -- W
signal D_CONTROL  : std_logic_vector(31 downto 0); -- R/W
signal E_CONTROL  : std_logic_vector(31 downto 0); -- R/W
signal F_CONTROL  : std_logic_vector(31 downto 0); -- R/W
signal G_CONTROL  : std_logic_vector(31 downto 0); -- W
signal D_DATA     : std_logic_vector(31 downto 0); -- R/W
signal E_DATA     : std_logic_vector(31 downto 0); -- R/W
signal F_DATA     : std_logic_vector(31 downto 0); -- R/W
signal MODE       : std_logic_vector(15 downto 0); -- W
signal SCRATCH    : std_logic_vector(15 downto 0); -- R/W
signal REVISION   : std_logic_vector(15 downto 0); -- R
signal PDL_CONTROL: std_logic_vector(15 downto 0); -- W
signal PDL_DATA   : std_logic_vector(15 downto 0); -- R/W

-- mux for REG_DOUT
signal selector1 : std_logic;

signal veto_tbox   : std_logic; -- connects TriggerBox veto to G_DOUT(0)
signal veto_in   : std_logic; -- connects GIN(0) to TriggerBox veto
signal veto_selection   : std_logic;
signal irq_enable   : std_logic;


signal REG_DOUT_TBOX  : std_logic_vector (15 DOWNTO 0);
signal REG_DOUT_CAEN  : std_logic_vector (15 DOWNTO 0);
signal bit_pattern : std_logic_vector(NBIT_TRIG-1 downto 0); 
signal serial_pattern : std_logic;
signal resolv_time : std_logic;
-- Register Bits
-- MODE Register
signal DELAY_SEL  : std_logic_vector(1 downto 0); -- "00" : PDL0 => Programmable Delay Line 0
                                                  -- "01" : PDL1 => Programmable Delay Line 0
                                                  -- "10" : DLO0  => Gated Delay Line Oscillator 0
                                                  -- "11" : DLO1  => Gated Delay Line Oscillator 1
signal UNIT_MODE  : std_logic; -- '0' : Coincidence Unit; '1' : I/O Register
signal OPERATOR   : std_logic; -- '0' : AND ; '1' : OR
signal PULSE_MODE : std_logic; --

--signal INT, reset_irq_cnt : std_logic;
signal int_qui : std_logic;

signal val_irq_cnt : std_logic_vector(15 downto 0);

-- Local Signals
signal A     : std_logic_vector(31 downto 0);
signal B     : std_logic_vector(31 downto 0);
signal C   : std_logic_vector(31 downto 0);

-- Coincidences
--signal veto_tbox   : std_logic; -- connects TriggerBox veto to G_DOUT(0)
signal COINC       : std_logic;
signal EXT_GATE    : std_logic;   
signal DLO_GATE    : std_logic;   
signal PDL_GATE    : std_logic;   
signal STARTDELAY  : std_logic;
signal STOPDELAY   : std_logic; 
signal STOP_PDL    : std_logic; 
signal STOP_DLO    : std_logic; 
signal CNT         : std_logic_vector(15 downto 0);
signal DLO_PULSE   : std_logic;
signal PDL_PULSEOUT: std_logic;
signal DLO_PULSEOUT: std_logic;

-- WAVEFORM GENERATOR
signal WVF_CNT     : std_logic_vector(4 downto 0) := (others => '0');
signal PDL_IN_i    : std_logic;
signal ENABLE_CNT  : std_logic;

signal RST : std_logic;

BEGIN
 tbox: trigger_box
		generic map(base_addr=>X"1090")
		port map(
			CLK => LCLK,
			RST => not nLBRES,
			MAINTRG => COINC,  
			RES_TIME => resolv_time,  
--			VETO_SIGNAL =>not G_DIN(0),  -- NIM input seems positive logic!!
			VETO_OUTPUT => veto_tbox,  -- used when G connector allows for VETO monitoring
			VETO_INPUT => veto_in,  -- used when G connector as VETO input
			VETO_SEL => veto_selection,  -- used when G connector as VETO input
			IRQ_ENA => irq_enable,  
			DEBUG_OUTPUT =>C(NBIT_DEBUG-1 downto 0),			  
			SUBTRG_INPUT_32 =>A,
			PATTERN => bit_pattern,
			PATTERN_SERIAL => serial_pattern,
			INT => int_qui, -- interrupt request signal
-- ============================ 
			address => REG_ADDR,
			data_in => REG_DIN,
			data_out => REG_DOUT_TBOX,
			n_rd => REG_RDEN,
			n_wr => REG_WREN, 	
			USR_ACCESS => USR_ACCESS,
			selector => selector1 
			);
			
			
-- conta_irq : counter16
-- 		port map(
-- 			clock_in => LCLK AND INT,
-- 			reset => reset_irq_cnt,
-- 			value_out => val_irq_cnt
-- 		);
-- 
-- 	gen_irq :process(resolv_time)
-- 	begin
-- 			if (RST = '1' OR reset_irq_cnt = '1')then
-- 				INT <= '0';
-- 			elsif rising_edge(resolv_time) then
-- 				INT <= '1';
-- 			end if;
-- 	end process;
-- 
--  
-- 	cnt_irq :process(LCLK)
-- 	begin
-- 			if (RST = '1')then
-- 				reset_irq_cnt <= '0';
-- 			elsif rising_edge(LCLK) then
-- 				reset_irq_cnt <= '0';
-- --				if(INT = '1' AND val_irq_cnt >= X"0190") then  -- 10us
-- 				if(INT = '1' AND val_irq_cnt >= X"0005") then  -- 125 ns
-- 					reset_irq_cnt <= '1';
-- 				end if;
-- 			end if;
-- 	end process;
				
				
	RST <=	not nLBRES; 

   --*************************************************
   -- USER DESIGN REVISION
   --*************************************************
   REVISION  <= X"0101"; -- 1.1
   
   --*************************************************
   -- SPARE PORT
   --*************************************************
   -- ALL Outputs driving 0
   SPARE_OUT <= (others => '0');
   SPARE_DIR <= (others => '1'); 

   --*************************************************
   -- LED PULSES
   --*************************************************
   RED_PULSE   <= '0';
   --GREEN_PULSE <= EXT_GATE;
  GREEN_PULSE <= resolv_time;  -- now the actual trigger is F(30)

   --*************************************************
   -- PORT SIGNAL STANDARD SELECTION                             
   --*************************************************
   -- Ports D,E,F,G signal standard set by register.
   D_LEV <= D_CONTROL(0); 
   E_LEV <= E_CONTROL(0); 
   F_LEV <= F_CONTROL(0); 

   --*************************************************
   -- PORT DIRECTION
   --*************************************************
   -- Ports D,E,F,G set by register.
   D_DIR  <= D_CONTROL(1);
   E_DIR  <= E_CONTROL(1);
   F_DIR  <= F_CONTROL(1);

   --*************************************************
   -- PORT G DIRECTION & LEVEL
   --*************************************************   
 -- G Port is used for VETO input from acquisition system
   G_LEV <= G_CONTROL(0); 
 --  G_DIR  <= '1';         -- Port G is Input only
--  G_DIR  <= '0';         -- Port G is output only, for veto

   --*************************************************
   -- PORT DATA OUT
   --*************************************************
   -- Ports D,E,F are driven by registers.
   D_DOUT <= D_DATA;
   E_DOUT <= E_DATA;
--   F_DOUT <= F_DATA;
-- ############################################
   F_DOUT(NBIT_TRIG -1 downto 0) <= bit_pattern; -- BitPattern output are LSBits of F port
	F_DOUT(31) <= COINC;  -- MainTrigger output is channel 31 on F port
	F_DOUT(30) <= resolv_time;
	F_DOUT(29) <= serial_pattern;
	-- PROVVISORIO PER GIORDANO
--	C(NBIT_TRIG+8-1 downto 8) <= bit_pattern;
--	C(31) <= COINC;
	
   --*************************************************
   -- GATE ON EXTERNAL CONNECTOR   
   --*************************************************
   -- EXT_GATE drives G connector.  
   --  Port G MUST be configured as an output.
   --               __________________________
   -- EXT_GATE  ___|                          |_______
   --               __________________________
   -- G_DOUT(0) ___|                          |_______
   --           ___                            _______
   -- G_DOUT(1)    |__________________________|
   --
--   G_DOUT(0)  <= EXT_GATE;

   G_DOUT(1)  <= not(EXT_GATE);

    -- G_DOUT(0) <= veto_tbox;
    
    
    
--////////////    
    G_DOUT(0) <= veto_tbox   when veto_selection = '1' else 'Z';
    G_DIR  <= '0' when veto_selection = '1' else '1';         -- Port G is output only, for veto
    
    veto_in <= not G_DIN(0) when veto_selection = '0' else '0';    
--////////////
    
    
    
--     G_DOUT(0)  <= C(0);
--     G_DOUT(1)  <= C(1);

  nINT <= not int_qui when irq_enable = '1' else '1';

   --*************************************************
   -- PDL DELAY LINES CONTROL
   --*************************************************
   -- PDLs can be configured by two registers:
   --  * PDL_CONTROL
   --  * PDL_DATA
   PDL_WR     <= PDL_CONTROL(0);
   PDL_DIR    <= PDL_CONTROL(1);
   PDL_SEL    <= PDL_CONTROL(2);
   PDL_WRITE  <= PDL_DATA(7 downto 0);
   --- END OF DELAY LINES CONTROLS
   
   A_STATUS <= A_DIN;
   B_STATUS <= B_DIN;
   C_STATUS <= C;
   
   --*************************************************
   -- MODE Register Bit Mapping       
   --*************************************************
   DELAY_SEL(0) <= MODE(0);
   DELAY_SEL(1) <= MODE(1);
   UNIT_MODE    <= MODE(3);
   OPERATOR     <= MODE(4);
   PULSE_MODE   <= MODE(5);
   
   
   --*************************************************
   -- Inport Port (A,B) Masking
   --*************************************************
   -- Single bits of input port A & B can be masked
   -- through a register.
   
   -- Masking of Port A 
   A <= A_DIN and A_MASK;
   
   -- Masking of Port B 
   B <= B_DIN and B_MASK;


   --**********************************************************
   -- Output Port (C) DRIVER
   --**********************************************************
   --  In this reference design, Port C can be driven
   --  in different mode depending on register content:
   --    (1) UNIT_MODE is driven by a bit of MODE REGISTER 
   --        in order to select Port C Driver. 
   --        If UNIT_MODE is set to '0' then 
   --        Port C is directly driven by C_CONTROL register.
   --        If UNIT_MODE is set to '1' then
   --        Port C is driven by the a logic operation
   --        on A and B port. Which logic operation to adopt
   --        is selected through the OPERATOR signal.
   --        OPERATOR signal is driven by bit 4 of MODE REGISTER.
   
   -- Select Logic Operation
--   P_OPER_SEL : process(OPERATOR, A, B)
--   begin
--     if OPERATOR = '0' then
--        C <= A and B;
--     else
--        C <= A or B;
--     end if;
--   end process;
   
   -- Select Port C driver based on a configuration bit.
   P_C_DRIVE: process(UNIT_MODE, C, C_MASK, C_CONTROL)
   begin
     if UNIT_MODE = '0' then
        C_DOUT <= C and C_MASK;
     else
        C_DOUT <= C_CONTROL;
     end if;
   end process;

   --**********************************************************
   -- Coincidence Processing     
   --**********************************************************
   -- COINC signal is a '1' whenever one bit of C is '1'.
   --COINC <= OR_REDUCE(C);
   
   STOPDELAY <= STOP_PDL or STOP_DLO;
   
   -- A '0' to '1' transition on COINC signal 
   -- starts the delay timer.
   P_COINC: process(COINC, STOPDELAY, nLBRES)
   begin
     if STOPDELAY='1' or nLBRES='0' then
       STARTDELAY <= '0';
     elsif COINC'event and COINC = '1' then
       STARTDELAY <= '1';
     end if;
   end process;

 
   --**********************************************************
   -- Select delay timer
   --**********************************************************
   P_DLY_SEL: process(DELAY_SEL, STARTDELAY,  
                      PDL_IN_i,  PDL0_OUT, PDL1_OUT,
                      DLO0_OUT,  DLO1_OUT)
   begin
     PDL0_IN       <= '0';
     PDL1_IN       <= '0';
     DLO0_GATE     <= '0';
     DLO1_GATE     <= '0';
     DLO_PULSE     <= '0';
     PDL_PULSEOUT  <= '0';
    case DELAY_SEL is
       when "00" =>          
                      PDL0_IN       <= PDL_IN_i;
                      PDL_PULSEOUT  <= PDL_IN_i and (not PDL0_OUT);

       when "01" =>           
                      PDL1_IN       <= PDL_IN_i;
                      PDL_PULSEOUT  <= PDL_IN_i and (not PDL1_OUT);

       when "10" =>   DLO0_GATE     <= STARTDELAY;       
                      DLO_PULSE     <= DLO0_OUT;
       when "11" =>   DLO1_GATE     <= STARTDELAY;       
                      DLO_PULSE     <= DLO1_OUT; 
       when others => null;
     end case;
   end process;    

   -- DDL WAVEFORM GENERATOR
   -- Monolithic DDL (3D3428) has a minimum pulse width specs (320 ns)
   -- for optimum linearity performance.
   --
   --
   --           _____________________         
   --   _______|                     |_________________
   --            _____________________            
   --   ________|                     |_________________
   --           _            
   --   _______||_______________________________________
   
   process(nLBRES, LCLK)
   begin
     if nLBRES = '0' then
       PDL_IN_i <= '0';
       WVF_CNT  <= (others => '0');
       ENABLE_CNT <= '0';
     elsif LCLK'event and LCLK='1' then 
       if STARTDELAY = '1' then
         PDL_IN_i   <= '1';
         ENABLE_CNT <= '1';
       end if;
       if ENABLE_CNT = '1' then
          WVF_CNT <= WVF_CNT + 1;
       end if;
       if WVF_CNT = "01101" then
         PDL_IN_i <= '0';
         WVF_CNT  <= (others => '0'); 
         ENABLE_CNT <= '0';
       end if;
     end if;
   end process;


  --****************************************
  -- DLO DELAY COUNTER
  --****************************************
  -- Counts pulses out of the selected delay 
  -- line before closing the GATE signal
  P_DLO_DELAY: process(nLBRES,DLO_PULSE, STARTDELAY)
  begin
    if ((nLBRES = '0') or (STARTDELAY = '0')) then
       CNT          <= (others => '0');
       STOP_DLO     <= '0';
       DLO_PULSEOUT <= '0';
    elsif DLO_PULSE'event and DLO_PULSE = '1' then
         CNT          <= CNT + 1;
         DLO_PULSEOUT <= '1';
         if CNT = GATEWIDTH then
            STOP_DLO     <= '1';
            DLO_PULSEOUT <= '0';
         end if;
       end if;
  end process;
  
  --****************************************
  -- PDL SINGLE SHOT ACQUISITION
  --****************************************
  -- This process detects the PDL pulse and resets
  -- the Coincidence register to allow a new coincidence
  -- to be detected.
  P_PDL_DELAY: process(nLBRES,PDL_PULSEOUT, STARTDELAY)
  begin
    if ((nLBRES = '0') or (STARTDELAY = '0')) then
       STOP_PDL  <= '0';
    elsif PDL_PULSEOUT'event and PDL_PULSEOUT = '0' then
       STOP_PDL  <= '1';
    end if;
  end process;
 
  --********************************************************************************
  -- DLOx: DELAY LINE OSCILLATORS
  --   GATE DRIVER
  --********************************************************************************

   --********************************************************************************
  -- PULSE MODE = '0' (GATEWIDTH = 3):
  --   EXT_GATE leading edge synchronous with PULSE leading egde.
  --               ____
  -- COINC     ___|    |________________________________________
  --                  ___     ___     ___     _
  -- DLO_PULSE ______|   |___|   |___|   |___| |________________
  --                  _______________________
  -- DLO_GATE  ______|                       |__________________
  --
   --********************************************************************************
  -- PULSE MODE = '1' (GATEWIDTH = 3):
  --   EXT_GATE leading edge synchronous with COINC leading egde.
  --               ____
  -- COINC     ___|    |________________________________________
  --                  ___     ___     ___     _
  -- DLO_PULSE ______|   |___|   |___|   |___| |________________
  --               __________________________
  -- DLO_GATE  ___|                          |__________________
  --
  DLO_GATE <= DLO_PULSEOUT when PULSE_MODE = '0' else
              STARTDELAY;

  --********************************************************************************
  -- PDLx: PROGRAMMABLE DELAY LINES
  --   GATE DRIVER
  --   NOTE: GATEWIDTH HAS NO EFFECT IN CASE OF A PDL-BASED GATE PULSE.
  --   THE GATE PULSE WIDTH DEPENDS ON CURRENT DELAY OF THE PDL CHIP.
  --********************************************************************************

   --********************************************************************************
  -- PULSE MODE = '0' :
  --   EXT_GATE leading edge synchronous with PULSE leading egde.
  --                  ____
  -- COINC        ___|    |________________________________________
  --                     ___ 
  -- PDL_PULSEOUT ______|   |______________________________________
  --                     ___
  -- PDL_GATE     ______|   |______________________________________
  --
   --********************************************************************************
  -- PULSE MODE = '1' :
  --   EXT_GATE leading edge synchronous with COINC leading egde.
  --                  ____
  -- COINC        ___|    |________________________________________
  --                     ___ 
  -- PDL_PULSEOUT ______|   |______________________________________
  --                  ______
  -- PDL_GATE     ___|      |______________________________________
  --              
  PDL_GATE <= PDL_PULSEOUT    when PULSE_MODE = '0' else
              STARTDELAY;
  

   -- GATE PULSE
   process(DELAY_SEL, PDL_GATE, DLO_GATE)
   begin
       case DELAY_SEL is
         when "00" | "01" =>    EXT_GATE  <= PDL_GATE;         -- PDL0, PDL1
         when "10" | "11" =>    EXT_GATE  <= DLO_GATE;         -- DLO0, DLO1                   
         when others => null;
       end case;
   end process;      

   --********************************************************************************
   -- USER REGISTERS SECTION
   --********************************************************************************
   
   -- WRITE REGISTERS
   P_WREG : process(LCLK, nLBRES)
   begin
      if (nLBRES = '0') then
         A_MASK       <= X"FFFFFFFF"; -- Default : Unmasked
         B_MASK       <= X"FFFFFFFF"; -- Default : Unmasked
         C_MASK       <= X"FFFFFFFF"; -- Default : Unmasked
         GATEWIDTH    <= X"0004";     -- Default : 
         C_CONTROL    <= X"00000000";
--         MODE         <= X"0008";     -- Default : I/O Register
         MODE         <= X"0000";     -- Default : TB
        SCRATCH      <= X"5A5A";
         G_CONTROL    <= X"00000000"; -- Default : Enable G port / Level=TTL
         D_CONTROL    <= X"00000000"; -- Default : Enable D port / Level=TTL
         D_DATA       <= X"00000000"; 
         E_CONTROL    <= X"00000000"; -- Default : Enable E port / Level=TTL
         E_DATA       <= X"00000000"; 
         F_CONTROL    <= X"00000000"; -- Default : Enable F port / Level=TTL
         F_DATA       <= X"00000000";
         PDL_CONTROL  <= X"0001";     -- DLY Buffer DIR = DLY -> FPGA; PDL Write Enabled
         PDL_DATA     <= X"0000";
       elsif LCLK'event and LCLK = '1' then
         if (REG_WREN = '1') and (USR_ACCESS = '1') then
           case REG_ADDR is
             when A_AMASK_L   => A_MASK(15 downto 0)      <= REG_DIN;
             when A_AMASK_H   => A_MASK(31 downto 16)     <= REG_DIN;
             when A_BMASK_L   => B_MASK(15 downto 0)      <= REG_DIN;
             when A_BMASK_H   => B_MASK(31 downto 16)     <= REG_DIN;
             when A_CMASK_L   => C_MASK(15 downto 0)      <= REG_DIN;
             when A_CMASK_H   => C_MASK(31 downto 16)     <= REG_DIN;
             when A_GATEWIDTH => GATEWIDTH                <= REG_DIN;
             when A_CCTRL_L   => C_CONTROL(15 downto 0)   <= REG_DIN;
             when A_CCTRL_H   => C_CONTROL(31 downto 16)  <= REG_DIN;   
             when A_MODE      => MODE                     <= REG_DIN;
             when A_SCRATCH   => SCRATCH                  <= REG_DIN; 
             when A_GCTRL     => G_CONTROL(15 downto 0)   <= REG_DIN; 
             when A_DCTRL_L   => D_CONTROL(15 downto  0)  <= REG_DIN;
             when A_DCTRL_H   => D_CONTROL(31 downto 16)  <= REG_DIN;
             when A_DDATA_L   => D_DATA   (15 downto  0)  <= REG_DIN;
             when A_DDATA_H   => D_DATA   (31 downto 16)  <= REG_DIN;
             when A_ECTRL_L   => E_CONTROL(15 downto  0)  <= REG_DIN;
             when A_ECTRL_H   => E_CONTROL(31 downto 16)  <= REG_DIN;
             when A_EDATA_L   => E_DATA   (15 downto  0)  <= REG_DIN;
             when A_EDATA_H   => E_DATA   (31 downto 16)  <= REG_DIN;
             when A_FCTRL_L   => F_CONTROL(15 downto  0)  <= REG_DIN;
             when A_FCTRL_H   => F_CONTROL(31 downto 16)  <= REG_DIN;
             when A_FDATA_L   => F_DATA   (15 downto  0)  <= REG_DIN;
             when A_FDATA_H   => F_DATA   (31 downto 16)  <= REG_DIN;
             when A_PDL_CTRL  => PDL_CONTROL              <= REG_DIN;
             when A_PDL_DATA  => PDL_DATA                 <= REG_DIN;
             when others      => null;
           end case;
         end if;
       end if;
     end process;
   
     
  -- READ REGISTERS
  P_RREG: process(LCLK, nLBRES)
  begin
       if (nLBRES = '0') then
         REG_DOUT_CAEN   <= (others => '0');
       elsif LCLK'event and LCLK = '1' then
         if (REG_RDEN = '1') and (USR_ACCESS = '1') then
           case REG_ADDR is
             when A_ASTATUS_L   => REG_DOUT_CAEN   <= A_STATUS (15 downto 0);
             when A_ASTATUS_H   => REG_DOUT_CAEN   <= A_STATUS (31 downto 16);
             when A_BSTATUS_L   => REG_DOUT_CAEN   <= B_STATUS (15 downto 0);
             when A_BSTATUS_H   => REG_DOUT_CAEN   <= B_STATUS (31 downto 16);
             when A_CSTATUS_L   => REG_DOUT_CAEN   <= C_STATUS (15 downto 0);
             when A_CSTATUS_H   => REG_DOUT_CAEN   <= C_STATUS (31 downto 16);
             when A_SCRATCH     => REG_DOUT_CAEN   <= SCRATCH; 
             when A_DCTRL_L     => REG_DOUT_CAEN   <= D_CONTROL(15 downto  0);
             when A_DCTRL_H     => REG_DOUT_CAEN   <= D_CONTROL(31 downto 16);
             when A_DDATA_L     => REG_DOUT_CAEN   <= D_DIN    (15 downto  0);
             when A_DDATA_H     => REG_DOUT_CAEN   <= D_DIN    (31 downto 16);
             when A_ECTRL_L     => REG_DOUT_CAEN   <= E_CONTROL(15 downto  0);
             when A_ECTRL_H     => REG_DOUT_CAEN   <= E_CONTROL(31 downto 16);
             when A_EDATA_L     => REG_DOUT_CAEN   <= E_DIN    (15 downto  0);
             when A_EDATA_H     => REG_DOUT_CAEN   <= E_DIN    (31 downto 16);
             when A_FCTRL_L     => REG_DOUT_CAEN   <= F_CONTROL(15 downto  0);
             when A_FCTRL_H     => REG_DOUT_CAEN   <= F_CONTROL(31 downto 16);
             when A_FDATA_L     => REG_DOUT_CAEN   <= F_DIN    (15 downto  0);
             when A_FDATA_H     => REG_DOUT_CAEN   <= F_DIN    (31 downto 16);
             when A_REVISION    => REG_DOUT_CAEN   <= REVISION;
             when A_PDL_CTRL    => REG_DOUT_CAEN   <= PDL_CONTROL;
             when A_PDL_DATA    => REG_DOUT_CAEN   <= X"00"  & PDL_READ;
             when A_DIDCODE     => REG_DOUT_CAEN   <= X"000" & '0' & D_IDCODE;
             when A_EIDCODE     => REG_DOUT_CAEN   <= X"000" & '0' & E_IDCODE;
             when A_FIDCODE     => REG_DOUT_CAEN   <= X"000" & '0' & F_IDCODE;
             when others        => REG_DOUT_CAEN   <= (others => '0');
           end case;
         end if;
       end if;
     end process;
--    REG_DOUT <= REG_DOUT_CAEN;
  REG_DOUT <= REG_DOUT_CAEN    when selector1 = '0' else
              REG_DOUT_TBOX;
   
END rtl;

