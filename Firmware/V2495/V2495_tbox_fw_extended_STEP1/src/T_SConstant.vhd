LIBRARY ieee;
USE ieee.std_logic_1164.all;

package T_Sconstants is
--OTHER DO NOT CHANGE
constant SUBTRIG_PATTERN_BUILDER : STD_LOGIC_VECTOR(15 downto 0) := X"EDBA";  --Lists input to be merged into trigger 
constant NBIT_DATAIN : integer := 16;
constant NBIT_DATAOUT : integer := 16;
constant NBIT_ADDR : integer := 16;
constant COUNTER_BUF: integer := 6;
constant NBIT_DEBUG : integer := 32;


--NUMERIC CONSTANT
constant NBIT_SUBTRIG : integer := 128;--NEVER TOUCH
constant NPOS_LM : integer := 128; --must be  NBIT_SUBTRIG*NBIT_TRIG/16 rounded to upper integer
constant NPOS_DELAY : integer := 64; --not used
constant NPOS_MULT : integer := 24;--must be NBIT_SUBTRIG*NSERIES_MTRIG/16 rounded to upper integer
constant NBIT_TRIG : integer := 16;
constant NBIT_MTRIG : integer := 8;
constant NSERIES_MTRIG : integer :=2;
constant NBIT_LMINPUT : integer := 128; -- must be=NBIT_SUBTRIG
constant NBIT_SCALER : integer := 32;

--MEMORY MAP DO NOT CHANGE
constant INFNFI2_BOARDMODEL : std_logic_vector(15 downto 0) := X"1080"; -- 	-- here we write 0x09BF, i.e. 2495
constant INFNFI2_BOARDDATA : std_logic_vector(15 downto 0) := X"1084";-- board data related to fw
constant INFNFI2_TBOX_ORD : std_logic_vector(15 downto 0) := X"1088";-- board output ordering register;
constant INFNFI2_TBOX_CTRL : std_logic_vector(15 downto 0) := X"1090"; -- 	-- (LSNibble=Debug Mux, bit15->Software Reset)
constant INFNFI2_TBOX_SETVETO	 : std_logic_vector(15 downto 0) := X"1094";	--   writing to this register sets the VETO signal 
constant INFNFI2_TBOX_RESETVETO	 : std_logic_vector(15 downto 0) := X"1098";	--   writing to this register resets the VETO signal 
constant INFNFI2_TBOX_RESETIRQ	 : std_logic_vector(15 downto 0) := X"109C";	--   writing to this register resets the IRQ signal 
--
constant INFNFI2_TBOX_GDGEN_DEL	 : std_logic_vector(15 downto 0) := X"1100";	--  Gate and Delay generator (resolving time) DELAY base addr (up to 64 input)
constant INFNFI2_TBOX_GDGEN_WID	 : std_logic_vector(15 downto 0) := X"1200";	--  Gate and Delay Generator (resolving time) WIDTH 
--
constant INFNFI2_TBOX_LMINPUT	 : std_logic_vector(15 downto 0) := X"1400";	-- Logic Matrix input registers base addr
constant INFNFI2_TBOX_LM_MULTINPUT  : std_logic_vector(15 downto 0) :=X"3300";  --LogicMatrix input registers for multiplicity 
--
--
constant INFNFI2_TBOX_LMOUTPUT	 : std_logic_vector(15 downto 0) := X"3400";  --  Logic Matrix output registers 
--
--
constant INFNFI2_TBOX_RED_BASE 	 : std_logic_vector(15 downto 0) := X"3440";	--  Reduction down scaler base and mask 
constant INFNFI2_TBOX_REDUCTION	 : std_logic_vector(15 downto 0) := X"3450";	--  Reduction down scaler factors 
--
constant INFNFI2_TBOX_BITPATTERN	 : std_logic_vector(15 downto 0) := X"3490"; --  bit pattern register 
constant INFNFI2_TBOX_TRIG_REST	 : std_logic_vector(15 downto 0) := X"3494"; --  bit pattern and main trigger resolving time 
constant INFNFI2_TBOX_TRIGMASK	 : std_logic_vector(15 downto 0) := X"3498";	--  trigger mask register 
constant INFNFI2_TBOX_AUTORST_PAT	 : std_logic_vector(15 downto 0) := X"349C";	--  bit0=1 enable bit pat reset after serial TX 
-- 
--
-- WARNING: counters are now 32-bit (not 16 as in Giordano's original project); there is only room for 16 triggers between  : std_logic_vector(15 downto 0) := X"3510 and  : std_logic_vector(15 downto 0) := X"3550!!
--
constant INFNFI2_TBOX_SCALE0	 : std_logic_vector(15 downto 0) := X"3510";	-- scaler 0 (pre veto) base addr (up to 32 triggers...NO! 16) 
constant INFNFI2_TBOX_SCALE1	 : std_logic_vector(15 downto 0) := X"3550";	-- scaler 1 (post veto) base addr (up to 32 triggers...NO! 16) 
constant INFNFI2_TBOX_SCALE2	 : std_logic_vector(15 downto 0) := X"3590";	-- scaler 2 (post reduction) base addr  (up to 32 triggers...NO! 16) 
constant INFNFI2_TBOX_ENDSCALE	 : std_logic_vector(15 downto 0) := X"35D0";	-- end of scaler counters 

constant INFNFI2_TBOX_MAINTR_WID	 : std_logic_vector(15 downto 0) := X"3600";	--  Main Trigger output width in 25ns units 
constant INFNFI2_TBOX_MAINTR_DEL	 : std_logic_vector(15 downto 0) := X"3604";	--  validation delay with respecto to Main Trigger 

constant INFNFI2_TBOX_LOGIC_ANA_MEM	 : std_logic_vector(15 downto 0) := X"4000";	-- base addr LA memory
constant INFNFI2_TBOX_LOGIC_ANA_END	 : std_logic_vector(15 downto 0) := X"7000";	-- end addr LA memory

end T_Sconstants;

