library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity MainTrigGen is  
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(TRG_I : in STD_LOGIC; 
		MAINTRG : out STD_LOGIC;
		CLK : in STD_LOGIC;
		RST : in STD_LOGIC;
		----------------------------BUS
		address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT - 1 downto 0);
		n_rd : in  STD_LOGIC;
		n_wr : in  STD_LOGIC;
		USR_ACCESS : in STD_LOGIC;
		selector: out  STD_LOGIC
		------------------------------
		);
end MainTrigGen;   

Architecture Behavioral of MainTrigGen is


component counter16
	port(
         reset    : in std_logic;
         clock_in : in std_logic;
         value_out : out std_logic_vector(NBIT_DATAout-1 downto 0)
         );

end component; 

component trigger_ff IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC ;
		enable		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC 
	);
end component;


signal reset_out_cnt, reset_out_cnt_delay, mainout,reset_qui, reset_qui_delay, reset_write, reset_write_delay, enable_delay, set_mainout : std_logic;
signal val_out_cnt : std_logic_vector(15 downto 0);
signal val_out_cnt_delay : std_logic_vector(15 downto 0);
signal register_data : std_logic_vector(NBIT_DATAOUT-1 downto 0);
signal delay_data : std_logic_vector(NBIT_DATAOUT-1 downto 0);

begin
		
mainout_latch: trigger_ff
	port map  ( 
			aclr => reset_qui or RST,
				enable => '1',
				data => '1',
				clock => set_mainout,
				q => mainout
			); 
			
conta_output : counter16
		port map(
			clock_in =>CLK AND mainout,
			reset => reset_out_cnt OR reset_write,
			value_out => val_out_cnt
		);

		
conta_delay : counter16
		port map(
			clock_in =>CLK AND enable_delay,
			reset => reset_out_cnt_delay OR reset_write_delay,
			value_out => val_out_cnt_delay
		);
		
	maintrg <= mainout;

    
	gen_delay :process(TRG_I)
	begin
			if (RST = '1' OR reset_qui_delay = '1')then
				enable_delay <= '0';
			elsif rising_edge(TRG_I) then
				enable_delay <= '1';
			end if;
	end process;

 
	cnt_delay :process(CLK)
	begin
			if (RST = '1')then
				reset_qui_delay <= '0';
				reset_out_cnt_delay <= '0';
				set_mainout <= '0';
			elsif rising_edge(CLK) then
				reset_qui_delay <= '0';
				reset_out_cnt_delay <= '0';
				set_mainout <= '0';
				if(enable_delay = '1' AND val_out_cnt_delay >= delay_data) then
					reset_qui_delay <= '1';
					reset_out_cnt_delay <= '1';
					set_mainout <= '1';
				end if;
			end if;
	end process;
	
	cnt_output :process(CLK)
	begin
			if (RST = '1')then
				reset_qui <= '0';
				reset_out_cnt <= '0';
			elsif rising_edge(CLK) then
				reset_qui <= '0';
				reset_out_cnt <= '0';
				if(mainout = '1' AND val_out_cnt >= register_data) then
					reset_qui <= '1';
					reset_out_cnt <= '1';
				end if;
			end if;
	end process;

	decode:process(rst,clk)
		begin
			if (RST = '1')then
				selector <='0';	
				register_data(NBIT_DATAOUT -1 downto 3) <= (others => '0');
				register_data(0) <= '1';
				register_data(1) <= '0'; 
				register_data(2) <= '0';
				reset_write <= '0';
				reset_write_delay <= '0';
				
			elsif rising_edge(clk)then
				reset_write <= '0';
				reset_write_delay <= '0';
				if((to_integer(unsigned(address)) = (base_addr))AND N_RD ='1' AND USR_ACCESS = '1') then	
					data_out <= register_data;
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr+2))AND N_RD ='1' AND USR_ACCESS = '1') then	
					data_out <= delay_data;
					selector <='1';
				else 
					selector <='0';
				end if;
				
				if((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1' AND USR_ACCESS = '1') then    
					register_data <= data_in;
					reset_write <= '1'; -- reset counter when changed value!
				elsif((to_integer(unsigned(address)) = (base_addr+2))AND N_WR ='1' AND USR_ACCESS = '1') then    
					delay_data <= data_in;
					reset_write_delay <= '1'; -- reset counter when changed value!
				end if;
				
			end if;
			
	end process decode;
	
	
end Behavioral;
