library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;



entity SUBTRG_MERGER is
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
END SUBTRG_MERGER;


ARCHITECTURE MAIN OF SUBTRG_MERGER IS
begin

CHC_TOT<=CHC_D+CHC_E+x"40";

process(IN_A,IN_B,IN_D,IN_E)
begin
		OUT_SUBTRG(127 downto 64)<=(others=>'0');
		OUT_SUBTRG(31 downto 0)<=IN_A;
		OUT_SUBTRG(63 downto 32)<=IN_B;
		IF(CHC_D=x"08") THEN
			OUT_SUBTRG(71 downto 64)<=IN_D(7 downto 0);
			IF(CHC_E=x"08") THEN
				OUT_SUBTRG(79 downto 72)<=IN_E(7 downto 0);
			ELSIF(CHC_E=x"20")THEN
				OUT_SUBTRG(103 downto 72)<=IN_E;
			END IF;
		ELSIF(CHC_D=x"20") THEN
			OUT_SUBTRG(95 downto 64)<=IN_D;
			IF(CHC_E=x"08") THEN
				OUT_SUBTRG(103 downto 96)<=IN_E(7 downto 0);
			ELSIF(CHC_E=x"20")THEN
				OUT_SUBTRG(127 downto 96)<=IN_E;
			END IF;
		END IF;
end process;
end main;