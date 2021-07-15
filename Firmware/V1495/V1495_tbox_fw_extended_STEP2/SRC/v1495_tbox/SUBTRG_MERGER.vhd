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
		IN_E:in std_logic_vector(31 downto 0);
		OUT_SUBTRG:out std_logic_vector(127 downto 0)
	);
END SUBTRG_MERGER;


ARCHITECTURE MAIN OF SUBTRG_MERGER IS

begin

process(IN_A,IN_B,IN_D,IN_E)
begin
for I in 0 to 3 loop
		case (SUBTRIG_PATTERN_BUILDER(4*i+3 downto 4*i)) IS
			WHEN x"A" => OUT_SUBTRG(32*i+31 downto 32*i)<=IN_A;
			WHEN x"B" => OUT_SUBTRG(32*i+31 downto 32*i)<=IN_B;
			WHEN x"D" => OUT_SUBTRG(32*i+31 downto 32*i)<=IN_D;
			WHEN x"E" => OUT_SUBTRG(32*i+31 downto 32*i)<=IN_E;
			WHEN others=>OUT_SUBTRG(32*i+31 downto 32*i)<=(others=>'0');
		end case;
end loop;
end process;
end main;