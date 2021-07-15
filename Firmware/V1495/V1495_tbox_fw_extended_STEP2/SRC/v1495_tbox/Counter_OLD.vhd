library ieee;
--library vector;                   -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Counter is
	--generic(counter: integer:= 0);
	port(clock    :	in std_logic;
         reset    : in std_logic;
         clock_in : in std_logic;
         --debug : out Integer;
         --debug_oldvalue: out Integer;
         value_out : out std_logic_vector(NBIT_SCALER-1 downto 0)
         );

end Counter;


architecture Behavioral of Counter is
signal counter : Integer :=0 ;

begin

count: process(clock,reset)
	
	variable temp : Integer:=0;						---variabile temporanea che memorizza il conteggio all'interno del processo
	variable old_value : Integer:= 0;						---variabile temporanea che memorizza il conteggio all'interno del processo

		begin
		--old_value := 0;
		if (reset = '1')then
			 temp := 0;
			 counter <= 0;
			  old_value := 0;
	    elsif (clock'event and clock = '1' )then
			
			if(clock_in= '1' and old_value = 0)then
				old_value := 1;
				temp := temp + 1;
				--counter<=counter + 1;
             --temp <= temp+1;
		    elsif(clock_in= '0' and old_value = 1) then
			    old_value := 0;
			end if;
		--old_value :=0;
  	    counter <= temp;
		end if;
	--debug_oldvalue <= old_value;
	--debug <= temp;
	--value_out <= std_logic_vector(to_unsigned(counter,NBIT_DATAOUT));	
	end process count;
	value_out <= std_logic_vector(to_unsigned(counter,NBIT_DATAOUT));


end behavioral;