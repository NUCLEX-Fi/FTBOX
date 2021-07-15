
-------------------------------------------------------------------------------
-- Title : debouncer
-- Project :
-------------------------------------------------------------------------------
-- File : a.vhd
-- Author : Luigi Bardelli <bardelli@fi.infn.it>
-- Company :
-- Last update: 2008/02/20
-- Platform :
-------------------------------------------------------------------------------
-- Description: used to remove "oscillations" from signals. EDGE SENSITIVE.
--
-- NOTA: modificato il 2009-01-14: ora e' davvero un debouncer,
--             mentre nel 2008 era solo un monostabile
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity debouncer is

  port (
    input  : in  std_logic;             -- ingresso
    clk    : in  std_logic;             -- clock
	 rst    : in std_logic;
    output : out std_logic);

end debouncer;

architecture rtl of debouncer is
  constant sig_w         : integer := 4;  -- signal width is 2**sig_w-1 clocks

  constant DESIRED_COUNT : integer := 8;  -- desired sig w: MUST be < than
                                          -- 2** sig_w-1  :  clock is 25ns

  signal counter    : unsigned (sig_w-1 downto 0) := (others => '0');  -- contatore

  signal flag : std_logic:='0';
  signal input_l: std_logic:='0';
  signal input_seen: std_logic:='0'; 
begin  -- rtl

  process(input,input_seen)
  BEGIN
    if rising_edge( input )  then  
--    if rising_edge( input ) and flag = '0' then  -- Corretto il 18/2/2015 Gab e Mau
		input_l <='1';
	end if;
	if input_seen = '1' and input ='0' then -- e' stato visto: reset.
--	if input_seen = '1'  then -- Corretto il 18/2/2015 Gab e Mau
			input_l <= '0';
	end if;
    
  end process;

  process(clk)
  begin
    if rising_edge(clk) then

		if input_l = '1' then
		   input_seen <='1'; -- resetto il latch;
			output <= '1';
			flag <= '1';
			counter <= (others => '0');
		else
   		 input_seen <='0'; -- default: non ho visto nulla...
			-- qui l'input e' 0: devo contare o no?
			if flag = '1' then --si devo contare, il segnale era alto
				counter    <= counter + 1;
				if counter >= to_unsigned(DESIRED_COUNT, sig_w) then
					-- fine della storia:
					flag <= '0';
					counter <= (others => '0');
					output <='0';
				end if;
			else 
				-- caso flag=0 e input 0
				output <= '0';
			end if;
			
		end if;
	end if;
  
  end process;
  
end rtl;


architecture RTL2 of debouncer is
	signal start_latch : std_logic;
	signal middle_latch : std_logic;
	constant DESIRED_COUNT : integer := 8;  -- desired sig w: MUST be < than
	signal compare : std_logic_vector(DESIRED_COUNT-2 downto 0);
	signal shifter_mem : std_logic_vector (DESIRED_COUNT-1 downto 0);
	signal or_latch : std_logic;
	signal islatch_pos : std_logic;
	signal islatch_pos_l1 : std_logic;
	signal islatch_pos_l2 : std_logic;
	signal islatch_neg : std_logic;
	signal islatch_neg_l1 : std_logic;
begin
	compare<=(others=>'0');
	or_latch<=start_latch or middle_latch;
	
	latch_at_start:process(input,clk)
	begin
		if (clk'event and clk='1') then
			start_latch<=input;
		end if;
	end process latch_at_start;
	
	latch_in_middle_pos:process(input,clk,islatch_pos,islatch_pos_l1)
	begin
		if(clk='0') then --async reset
			islatch_pos<='0';
		elsif (input'event and input='1') then --sensible only during positive lobe
			islatch_pos<='1';
		end if;
		if(clk'event and clk='0') then
			islatch_pos_l1<=islatch_pos;
		end if;
		if(clk'event and clk='1') then
			islatch_pos_l2<=islatch_pos_l1;
		end if;
	end process;
		
	latch_in_middle_neg:process(input,clk,islatch_neg)
	begin
		if(clk='1') then --async reset
			islatch_neg<='0';
		elsif (input'event and input='1') then --sensible only during negative lobe
			islatch_neg<='1';
		end if;
		if(clk'event and clk='1') then
			islatch_neg_l1<=islatch_neg;
		end if;
	end process;
	
	middle_latch<=islatch_neg_l1 or islatch_pos_l2;
	
	shiftreg:process(rst,clk,or_latch,shifter_mem)
	begin
		if(rst='1') then
			shifter_mem<=(others=>'0');
			output<='0';
		elsif(clk'event and clk='1') then
			shifter_mem(DESIRED_COUNT-1 downto 1)<=shifter_mem(DESIRED_COUNT-2 downto 0);
			shifter_mem(0)<=or_latch;
			if(shifter_mem(DESIRED_COUNT-2 downto 0)=compare and or_latch='0') then
				output<='0';
			else	
				output<='1';
			end if;
		end if;
	end process shiftreg;
end RTL2;
	
	
	
	