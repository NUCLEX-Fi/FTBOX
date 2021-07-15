library ieee;
--library vector;                   -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Busy is 
	
	port(TRG_I : in STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); ---da cambiare dimensione in 32 bit
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0);
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 VETO_SIGNAL : in STD_LOGIC
		 );
	end Busy;

Architecture Behavioral of Busy is
begin

process(clk,rst,veto_signal,TRG_I)
begin
		if (Veto_signal = '1')then
				TRG_O <= (others =>'0');
		else
			TRG_O <= TRG_I;
		end if;end process;
end Behavioral;