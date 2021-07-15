-------------------------------------------------------------------------------
-- Title      : bit counter
-- Project    : 
-------------------------------------------------------------------------------
-- File       : bit_count.vhd
-- Author     : Gabriele Pasquali pasquali@fi.infn.it
-- Company    : 
-- Last update: 2012/06/28
-- Platform   : 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity bit_count is
  port (
    bit_in    : in  std_logic_vector(127 downto 0);  -- bits to be counted
    clk       : in  std_logic;          -- clock signal
	 rst		  : in std_logic;
    mult      : out  std_logic_vector(7 downto 0);  -- majority logic outputs  mult[0]=1 if at least 1 input true, etc.
	 dout : out  STD_uLOGIC_vector(7 downto 0);
    VETO      : in STD_LOGIC            -- general VETO: trigger ok only if veto=0
	);
end bit_count;

architecture rtl of bit_count is
   signal  cnt : std_ulogic_vector(7 downto 0);
	signal mult_int:std_logic_vector(7 downto 0);
	--moved externally
  --component debouncer
    --port (
      --input  : in  std_logic;
     -- clk    : in  std_logic;
      --output : out std_logic);
  --end component;
  
  component sum128 IS
        PORT(
		  a : IN Std_Logic_vector(1 TO 128);
        sum : OUT Std_uLogic_vector(7 downto 0) 
		  );
   END component;

begin  -- rtl
   
-- moved externally	
--  canali    : for kphos in NBITS-1 downto 0 generate
--      Dl : debouncer
--        port map (
--          input  => bit_in(kphos),
--          clk    => clk,
--          output => clean_input(kphos)
--          );
-- end generate canali;
--			 

  count_bits : sum128
  port map (
      a => bit_in,
      sum => cnt
  );
	
	dout <= cnt;

	  process (cnt,rst,clk)
     begin  -- process
			if(rst='1') then
				mult_int<=(others=>'0');
			elsif clk'event and clk='1' then
				for i IN 0 to 7 loop
					if to_integer(unsigned(cnt)) > i then
						mult_int(i)<='1';
					else 
						mult_int(i)<='0';
					end if;
				end loop;
			end if;
	 end process;
	 
	 mult<=mult_int;
	 
	 --the output is a 8 bit sequence containing M>=1,M>=2,M>=3...

end rtl;
