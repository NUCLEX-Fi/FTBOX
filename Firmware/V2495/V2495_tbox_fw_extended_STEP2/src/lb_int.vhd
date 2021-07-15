-- lb_int.vhd
-- -----------------------------------------------------------------------
-- V2495 User Local Bus Interface (slave)
-- -----------------------------------------------------------------------
--  Date        : Jul 2016
--  Contact     : support.nuclear@caen.it
-- (c) CAEN SpA - http://www.caen.it   
-- -----------------------------------------------------------------------
-- 
--    Functions
--    ------------------------
--
--    This module implements local bus slave interface.
--    Only single register read/write operations are supported.
--    Registers can be implemented into the 0x1000-0x7EFF address range.
--    Register space is divided into monitor registers (read only) and
--    control registers (read/write access).
--    Both registers are available to the external logic through two
--    ports (mon_regs/ctrl_regs), which are arrays of 32-bit values.
--    A dedicated interface is available for an external gate and dely control
--    IP: its configuration registers are mapped in the 'x7f00-0x7F10 address
--    range over local bus (see package declaration).
--    
-- -----------------------------------------------------------------------
-- $Id: lb_int.vhd,v 1.2 2021/07/12 14:51:54 bini Exp $
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;  
use IEEE.std_logic_unsigned.all;  
use work.V2495_pkg.all;
use work.T_SConstants.all;
     
-- ----------------------------------------------
entity lb_int is
-- ----------------------------------------------
    port(
      reset      : in     std_logic;                     -- reset (active high)
      clk        : in     std_logic;                     -- System clock (50 MHz)
      -- Local Bus in/out signals
      nBLAST     : in     std_logic;                     -- Last transfer (active low)
      WnR        : in     std_logic;                     -- Write/Read
      nADS       : in     std_logic;                     -- Address strobe (active low)
      nREADY     : out    std_logic;                     -- Slave ready (active low)
      LAD        : inout  std_logic_vector(15 DOWNTO 0); -- Data/Address bus

      -- Gate/Delay registers  
--       gd_ready   : in  std_logic;                        -- Ready from gd_control
--       gd_data_rd : in  std_logic_vector(31 downto 0);    -- Data read from G&D 
--       gd_write   : out std_logic;                        -- Write strobe for G&D
--       gd_read    : out std_logic;                        -- Read Strobe for G&D
--       gd_data_wr : out std_logic_vector(31 downto 0);    -- Data to write to G&D
--       gd_command : out std_logic_vector(15 downto 0);    -- G&D command
      
--       -- Register interface          
--       mon_regs   : in     MONITOR_REGS_T;                -- Monitor registers
--       ctrl_regs  : out    CONTROL_REGS_T                 -- Control registers
-- INTERFACE TO OLD BUS
      REG_WREN    : OUT     std_logic;                       -- Write pulse (active high)
      REG_RDEN    : OUT     std_logic;                       -- Read  pulse (active high)
      REG_ADDR    : OUT     std_logic_vector (15 DOWNTO 0);  -- Register address
      REG_DIN     : OUT     std_logic_vector (15 DOWNTO 0);  -- Data to trigger box
      REG_DOUT    : IN    std_logic_vector (15 DOWNTO 0);    -- Data from trigger box
      USR_ACCESS  : OUT     std_logic                       -- Current register access is 
                                                            -- at user address space(Active high)

      
    );
end lb_int;

-- ---------------------------------------------------------------
architecture rtl of lb_int is
-- ---------------------------------------------------------------

--     type   LBSTATE_type is (LBIDLE, LBWRITEL, LBWRITEH, LBREADL, LBREADL2, LBREADH, LBREADH2);
    type   LBSTATE_type is (LBIDLE, LBWRITEL, LBWRITEH, LBREADL, LBREADH);
    signal LBSTATE : LBSTATE_type;
    
    -- Output Enable of the LAD bus (from User to Vme)
    signal LAD_oe     : std_logic;
    -- Data Output to the local bus
    signal LAD_out    : std_logic_vector(15 downto 0);
    signal LAD_in    : std_logic_vector(15 downto 0);
    -- Lower 16 bits of the 32 bit data
--     signal dtl       : std_logic_vector(15 downto 0);
    -- Address latched from the LAD bus
    signal addr      : std_logic_vector(15 downto 0);
    signal addr_qui      : std_logic_vector(15 downto 0);
    

    
-----\
begin --
-----/


  REG_ADDR <= addr_qui;

    -- Local Bus data bidirectional control
  LAD <= REG_DOUT when LAD_oe = '1' else (others => 'Z');
  REG_DIN <= LAD_out;
  
   
  -- --------------------------
  --  Local Bus state machine
  -- --------------------------  
  process(clk, reset)
--        variable rreg, wreg   : std_logic_vector(31 downto 0);
  begin
    if (reset = '1') then
      nREADY        <= '1';
      LAD_oe        <= '0';
--      rreg          := (others => '0');
--      wreg          := (others => '0');
      addr          <= (others => '0');
      addr_qui          <= (others => '0');
      LAD_out       <= (others => '0');
--       ctrl_regs_int <= (others=>(others => '0'));
      LBSTATE       <= LBIDLE;
      USR_ACCESS <= '0';
      REG_RDEN <= '0';
      REG_WREN <= '0';
    elsif rising_edge(clk) then
      
      case LBSTATE is
        
        -- Idle state.
        -- Wait for local bus start of cycle.
        -- If an address strobe is given,
        -- the address is latched and access type is decoded.
        when LBIDLE  =>  
          LAD_oe   <= '0';
          nREADY  <= '1';
          USR_ACCESS <= '0';
           REG_WREN <= '0';
           REG_RDEN <= '0';
           if (nADS = '0') then        -- start cycle
            addr <= LAD;              -- Address Sampling
            addr_qui <= LAD;              -- Address Sampling
            USR_ACCESS <= '1';
            if (WnR = '1') then 
              -- Write Access
              nREADY   <= '0';
              LBSTATE  <= LBWRITEL;
              REG_WREN <= '1';
              REG_RDEN <= '0';
            else                      
              -- Read Access
              nREADY    <= '1';
              REG_WREN <= '0';
              REG_RDEN <= '1';
              LBSTATE   <= LBREADL;
            end if;
          end if;

        -- Latch data to write (lower 16-bit)  
        when LBWRITEL => 
          USR_ACCESS <= '1';
          LAD_out <= LAD;
          nREADY   <= '0';
          if (nBLAST = '0') then
            LBSTATE  <= LBIDLE;
            nREADY   <= '1';
          else
            LBSTATE  <= LBWRITEH;
          end if;
                       
        -- Write register                       
        when LBWRITEH =>   
            USR_ACCESS <= '1';
          
            nREADY   <= '0';
            LBSTATE  <= LBIDLE;
          

            
        -- Read register 
        -- transfer lower 16-bit register content        
        when LBREADL =>  
          
          nREADY    <= '0';
          USR_ACCESS <= '1';
          LAD_oe  <= '1';
          
          
--           if(addr = X"1084") then
--                 LAD <= X"CAFE";
--           else
--                 LAD <= REG_DOUT;
--           end if;
         if( (addr>=INFNFI2_TBOX_SCALE0 AND addr<INFNFI2_TBOX_ENDSCALE)
          OR (addr>=INFNFI2_TBOX_LOGIC_ANA_MEM AND addr<INFNFI2_TBOX_LOGIC_ANA_END)) then
                    addr_qui  <= std_logic_vector(unsigned(addr)+2);
--                     LAD <= REG_DOUT;
                    LBSTATE <= LBREADH;
           else
 --                             LAD <= REG_DOUT;
                    LBSTATE <= LBIDLE;
           end if;

    
--           LBSTATE <= LBREADL2;
--           LBSTATE <= LBREADH;
--           LAD_out <= rreg(15 downto 0);


--        when LBREADL2 =>  
--           
--           nREADY    <= '0';
--           USR_ACCESS <= '1';
--           LAD_oe  <= '1';
--           
--           
--  --         if(addr = X"1084") then
--  --               LAD <= X"CAFE";
--  --         else
--                 LAD <= REG_DOUT;
--  --         end if;
-- 
--      
--           LBSTATE <= LBREADH;
-- 
--  


        -- Read register
        -- Transfer upper 16-bit register content
        when LBREADH =>  
          nREADY    <= '0';
          USR_ACCESS <= '1';
--           LAD <= (others => '0');
          LAD_oe  <= '1';
--          addr_qui  <= (others => '0');
--           if(addr>=INFNFI2_TBOX_SCALE0 AND addr<INFNFI2_TBOX_ENDSCALE) then
--                     addr_qui  <= std_logic_vector(unsigned(addr)+2);
-- --                     LAD <= REG_DOUT;
--                     LBSTATE <= LBREADH2;
--            else
--  --                             LAD <= REG_DOUT;
--                     LBSTATE <= LBIDLE;
--            end if;
--           LAD_out <= rreg(31 downto 16);
--           LBSTATE <= LBREADH2;
--           LBSTATE <= LBREADH;
             LBSTATE <= LBIDLE;

--        when LBREADH2 =>  
--           nREADY    <= '0';
--           USR_ACCESS <= '1';
--           LAD_oe  <= '1';
--           addr_qui  <= std_logic_vector(unsigned(addr)+2);
-- --           LAD <= REG_DOUT;
-- --           LAD_out <= rreg(31 downto 16);
--           LBSTATE <= LBIDLE;
         
          
         end case;

    end if;
  end process;

end rtl;

