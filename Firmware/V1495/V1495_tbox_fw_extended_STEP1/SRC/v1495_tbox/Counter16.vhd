library ieee;
--library vector;                   -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Counter16 is
	--generic(counter: integer:= 0);
	port(reset    : in std_logic;
         clock_in : in std_logic;
         --debug : out Integer;
         --debug_oldvalue: out Integer;
         value_out : out std_logic_vector(15 downto 0)
         );

end Counter16;


architecture Behavioral of Counter16 is
signal counter : Integer :=0 ;

begin

count: process(clock_in,reset)
	
	variable temp : Integer:=0;						---variabile temporanea che memorizza il conteggio all'interno del processo

		begin
		if (reset = '1')then
			 temp := 0;
	    elsif(rising_edge(clock_in))then
				temp := temp + 1;
			end if;
  	    counter <= temp;
	end process count;
	value_out <= std_logic_vector(to_unsigned(counter,16));


end behavioral;