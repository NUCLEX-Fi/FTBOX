LIBRARY ieee;
USE ieee.std_logic_1164.all;

package T_Sconstants is
constant INFNFI_BOARDMODEL : std_logic_vector(15 downto 0) := X"1080"; -- 	-- here we write 0x09BF, i.e. 2495
constant INFNFI_BOARDDATA : std_logic_vector(15 downto 0) := X"1084"; --
constant NBIT_SUBTRIG : integer := 32;
constant NPOS_DELAY : integer :=16;
constant NBIT_TRIG : integer := 8;
constant NBIT_LMINPUT : integer := 40; -- must be=NBIT_SUBTRIG+NBIT_TRIG
constant NPOS_LM : integer := 40; --must be (NBIT_SUBTRIG+NBIT_TRIG)*NBIT_TRIG/8 rounded to the upper integer
constant NBIT_DATAIN : integer := 16;
constant NBIT_DATAOUT : integer := 16;
constant NBIT_ADDR : integer := 16;
constant NBIT_DEBUG : integer := 32;
constant NBIT_SCALER : integer := 32;
constant COUNTER_BUF: integer := 6;


end T_Sconstants;

