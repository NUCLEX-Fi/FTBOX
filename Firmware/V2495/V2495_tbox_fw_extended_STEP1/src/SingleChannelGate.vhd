library ieee;
--library vector;                   -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity SingleChannelGate is
	--generic(counter: integer:= 0);
	port(
		reset    : in std_logic;
      clk : in std_logic;
      input :in std_logic;
		window_len : in std_logic_vector(16 downto 0);
		output: out std_logic
     );
end SingleChannelGate;


architecture Behavioral of SingleChannelGate is

signal counter : std_logic_vector(16 downto 0); 
signal internal_reset:std_logic;
signal q1 : std_logic;
signal q2 : std_logic;

begin

--first latch (input)
process(input,internal_reset,reset)
begin
	if((internal_reset or reset)='1') then
		q1<='0';
	elsif input'event and input='1' then
		q1<='1';
	end if;
end process;

--latch(clock)
process(q1,internal_reset,reset,clk)
begin
	if(reset='1') then	
		q2<='0';
	elsif(clk'event and clk='1') then
		if(internal_reset='1')then
			q2<='0';
		else
			q2<=q1;
		end if;
	end if;
end process;

process(reset,clk,q2,counter)
begin
	if(reset='1') then
		internal_reset<='0';
		counter(16 downto 2)<=(others=>'0');
		counter(1 downto 0)<="01";
	elsif clk'event and clk='1' then
		--gestione internal reset
		internal_reset<='0';
		if (counter=window_len) then
			internal_reset<='1';
		end if;
		
		--gestione counter
		if(counter=window_len) then
			counter(16 downto 2)<=(others=>'0');
			counter(1 downto 0)<="01";
		elsif q2='1' then
			counter<=counter+1;
		else
			counter<=counter;
		end if;
	end if;
end process;

output<=q2;
end Behavioral;
	