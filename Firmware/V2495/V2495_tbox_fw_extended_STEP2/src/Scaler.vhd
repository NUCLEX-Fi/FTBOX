library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;
use ieee.numeric_std.all;     			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Scaler is
	 
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(
		clock	: in  STD_LOGIC;	-- Ingresso di clock.(rise edge.)
		reset	: in  STD_LOGIC;	-- Ingresso di reset (att. alto.).
		fetch    :in  std_logic_vector(NBIT_TRIG-1 downto 0);	-- Ingresso valore dal bus principale linea_0
		  ----------------------------BUS
		  address : in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0);
		  data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN-1 downto 0);
		  data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT-1 downto 0);
		  n_rd : in  STD_LOGIC;
		  n_wr : in  STD_LOGIC;
		  USR_ACCESS : in STD_LOGIC;
		  selector: out  STD_LOGIC
		  --base_addr: in STD_LOGIC_VECTOR(NBIT_ADDR-1 downto 0)
	     -------------------------------
		 );
end Scaler;

architecture behavioral of Scaler is
type cnt_array is array(0 to NBIT_TRIG -1) of std_logic_vector(NBIT_SCALER-1 downto 0);
signal cnt: cnt_array; 

--signal temp: std_logic_vector(15 downto 0);
--signal fetch_sig: std_logic_vector(fetch'RANGE);


component Counter
	
	
	port( 
		  reset : in std_logic;
          clock_in : in std_logic;
          value_out : out std_logic_vector(NBIT_SCALER-1 downto 0)
        );
end component;       
--	 sync : process(clock, reset)
--	 begin
--	   if reset='1' then
--	   elsif clock'event and clock='1' then 
--		fetch_sig <= fetch;
--	   end if;
--    end process sync;


begin

-------------------------------Instantiate Counter
contatori: for kcounter in NBIT_TRIG-1 downto 0 generate
       conta : Counter
       
      
       port map(
				reset => reset,
				clock_in  => fetch(kcounter),
                value_out => cnt(kcounter)
               );
end generate contatori;
---------------------------------
selection: process(clock,reset)
	begin	
	if (reset = '1')then 
		selector <='0';
	elsif rising_edge(clock)then
		selector <='0';
		if (n_rd = '1') and (USR_ACCESS = '1') then
			decode_addr: for i in 0 to NBIT_TRIG-1 loop
				if(to_integer(unsigned(address)) = (base_addr+  4*i)) then
					selector <= '1';
					data_out <=cnt(i)(15 downto 0);
				end if;
				if(to_integer(unsigned(address)) = (base_addr+  4*i + 2)) then
					selector <= '1';
					data_out <=cnt(i)(31 downto 16);
				end if;
			end loop;
			else selector <='0';
		end if;
	end if;
end process selection;
	
end behavioral;										
