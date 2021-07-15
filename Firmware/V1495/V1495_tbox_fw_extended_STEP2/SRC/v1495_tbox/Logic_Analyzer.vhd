--  Logic Analyzer stores up to 4096 values in memory (100us)
-- Values are taken from the DEBUG bus which is driven by the general MUX
--  The trigger is given by an OR of selected bits (selected bits are set to 1
--   in the trig_mask register).
--  A pre-trigger portion of max len 2048 can be set using the pre_trigger register
--  Data memory is mapped to the first 0x1000 addresses starting at base_addr
--  Write something to address base_addr to rearm the trigger
library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Logic_Analyzer is  
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(INPUT : in STD_LOGIC_VECTOR(NBIT_DEBUG -1 downto 0); 
		EXT_TRIGGER : in STD_LOGIC;
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
end Logic_Analyzer;   



Architecture Behavioral of Logic_Analyzer is

constant NBIT_ADDR_SR : integer := 11;
constant NBIT_ADDR_MEM : integer := 12;

constant MEMORY_LEN  : integer := 12288; -- 0x3000 in byte NEW CAEN FIRM :-(((

constant ADR_PRE_TRIGGER  : STD_LOGIC_VECTOR (NBIT_ADDR-1 downto 0) := X"3000";
constant ADR_CURR_PTR  : STD_LOGIC_VECTOR (NBIT_ADDR-1 downto 0) := X"3002";
constant ADR_TRG_PTR   : STD_LOGIC_VECTOR (NBIT_ADDR-1 downto 0) := X"3004";
constant ADR_LAST_PTR  : STD_LOGIC_VECTOR (NBIT_ADDR-1 downto 0) := X"3006"; 
constant ADR_TRIG_MASK_HI  : STD_LOGIC_VECTOR (NBIT_ADDR-1 downto 0) := X"3008"; 
constant ADR_TRIG_MASK_LO  : STD_LOGIC_VECTOR (NBIT_ADDR-1 downto 0) := X"300A"; 


type sm_state is (rearm, wait_trigger, got_trigger,wait_mem_full, mem_full) ;

signal sm_state_cs: sm_state;
signal sm_state_fs: sm_state ;
signal curr_ptr, trg_ptr : std_logic_vector (NBIT_ADDR_MEM-1 downto 0);
signal last_ptr : std_logic_vector (NBIT_ADDR_MEM-1 downto 0);

signal sr_wr_ptr, sr_rd_ptr : STD_LOGIC_VECTOR(NBIT_ADDR_SR-1 downto 0);
signal pre_trigger : std_logic_vector (NBIT_ADDR_SR-1 downto 0);

signal shift_reg_q : std_logic_vector(NBIT_DEBUG-1 downto 0);
signal memory_q : std_logic_vector(NBIT_DEBUG-1 downto 0);
signal WE_MEM, TRIGGER : std_logic;
signal trig_mask,trig_masked,compare_to : std_logic_vector(NBIT_DEBUG-1 downto 0);
signal ctrl_reg : std_logic_vector(NBIT_DATAIN-1 downto 0);
signal REARM_SIGNAL : std_logic;
signal SW_TRIGGER : std_logic;

signal address_qui : std_logic_vector(NBIT_ADDR-1 downto 0);

component LA_shift_reg IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (NBIT_ADDR_SR-1 DOWNTO 0);
		rden		: IN STD_LOGIC  := '1';
		wraddress		: IN STD_LOGIC_VECTOR (NBIT_ADDR_SR-1 DOWNTO 0);
		wren		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component;

component LA_memory IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (NBIT_ADDR_MEM-1 DOWNTO 0);
		rden		: IN STD_LOGIC  := '1';
		wraddress		: IN STD_LOGIC_VECTOR (NBIT_ADDR_MEM-1 DOWNTO 0);
		wren		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component;


begin

--REARM_SIGNAL <= ctrl_reg(15);

LA_shift_reg_1 : LA_shift_reg
	PORT MAP
	(
		clock=>CLK,
		data=>INPUT,
		rdaddress=>sr_rd_ptr,
		rden=>'1',
		wraddress=>sr_wr_ptr,
		wren=>'1',
		q=>shift_reg_q
	);

LA_memory_1 : LA_memory 
	PORT MAP
	(
		clock=>CLK,
		data=>shift_reg_q,
		rdaddress=>address_qui(NBIT_ADDR-3 downto 2),
		rden=> '1',  -- n_rd,
		wraddress=>curr_ptr,
		wren=>WE_MEM,
		q=>memory_q
	);


address_qui <= (address-base_addr);
--bit_low_word <= address_qui(1);

   sm_sync : process(CLK, RST)
	 begin
	   if RST='1' then
		sm_state_cs <= mem_full;
		sr_wr_ptr <= (others => '0');
	   elsif clk'event and clk='1' then 
		sr_wr_ptr <= sr_wr_ptr+1;
                if REARM_SIGNAL = '1' then
                  curr_ptr <= (others => '0');
                  trg_ptr <= (others => '0');
                  sm_state_cs <= rearm;
                else
                  if sm_state_cs = wait_trigger then
                    if TRIGGER = '1' OR SW_TRIGGER = '1' OR EXT_TRIGGER = '1' then
                     sm_state_cs <= got_trigger;
                    else
                     sm_state_cs <= sm_state_fs;
                    end if;
                  elsif sm_state_cs = got_trigger then  
                    sr_rd_ptr <= sr_wr_ptr - pre_trigger;
                    sm_state_cs <= wait_mem_full;
                  elsif sm_state_cs = wait_mem_full then                    
                    if curr_ptr = last_ptr then
                      sm_state_cs <= mem_full;
                    else
                      curr_ptr <= curr_ptr+1;
                      sr_rd_ptr <= sr_rd_ptr+1;
                      sm_state_cs <= wait_mem_full;
                    end if;
                  else
                      sm_state_cs <= sm_state_fs;
                  end if;
                end if;
	   end if;
    end process sm_sync;

sm_operations: process(sm_state_cs)
      begin
        case  sm_state_cs is 
          when rearm =>
            WE_MEM <= '0';
            sm_state_fs <= wait_trigger;
          when wait_trigger => 
            WE_MEM <= '0'; 
            sm_state_fs <= sm_state_cs;
          when got_trigger => 
            WE_MEM <= '0';
            sm_state_fs <= wait_mem_full;
          when wait_mem_full =>
            WE_MEM <= '1';
             sm_state_fs <= sm_state_cs;
          when mem_full =>
            WE_MEM <= '0';
            sm_state_fs <= sm_state_cs;
        end case;
end process sm_operations;

	compare_to <= (others => '0');
    trig_masked <= INPUT AND trig_mask;
	trig_or :process(trig_masked,compare_to)
	begin
			if (trig_masked = compare_to) then      ----Or dei trigger
				TRIGGER <= '0';
			else 
				TRIGGER <= '1';
			end if;
	end process;


	decode:process(rst,clk)
		begin
			if (RST = '1')then
				selector <='0';	
				trig_mask <= (others => '0');
				last_ptr<=(others =>'1');
				pre_trigger<=(NBIT_ADDR_SR-1 =>'0', NBIT_ADDR_SR-2 =>'1',others=>'0');
				SW_TRIGGER<='0';
			elsif rising_edge(clk)then
				REARM_SIGNAL <= '0';
				SW_TRIGGER <= '0';
				if((to_integer(unsigned(address)) >= (base_addr))AND (to_integer(unsigned(address)) < (base_addr+MEMORY_LEN))AND
							N_RD ='1' AND USR_ACCESS = '1') then
					selector <='1';
					if(address(1) = '1') then
						data_out <= memory_q(15 downto 0);
					else
						data_out <= memory_q(31 downto 16);
					end if;
				elsif((to_integer(unsigned(address)) = (base_addr +ADR_TRIG_MASK_LO))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out <= trig_mask(15 downto 0);
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +ADR_TRIG_MASK_HI))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out <= trig_mask(31 downto 16);
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +ADR_PRE_TRIGGER))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_ADDR_SR-1 downto 0) <= pre_trigger;
					data_out(NBIT_DATAOUT-1 downto NBIT_ADDR_SR) <= (others=>'0');
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +ADR_CURR_PTR))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_ADDR_MEM-1 downto 0) <= curr_ptr;
					data_out(NBIT_DATAOUT-1 downto NBIT_ADDR_MEM) <= (others=>'0');
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +ADR_LAST_PTR))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_ADDR_MEM-1 downto 0) <= last_ptr;
					data_out(NBIT_DATAOUT-1 downto NBIT_ADDR_MEM) <= (others=>'0');
					selector <='1';
				elsif((to_integer(unsigned(address)) = (base_addr +ADR_TRG_PTR))AND N_RD ='1' AND USR_ACCESS = '1') then
					data_out(NBIT_ADDR_MEM-1 downto 0) <= trg_ptr;
					data_out(NBIT_DATAOUT-1 downto NBIT_ADDR_MEM) <= (others=>'0');
					selector <='1';
				else 
					selector <='0';
				end if;
				
				if((to_integer(unsigned(address)) = (base_addr))AND N_WR ='1' AND USR_ACCESS = '1') then
					REARM_SIGNAL <= '1';
				elsif((to_integer(unsigned(address)) = (base_addr+2))AND N_WR ='1' AND USR_ACCESS = '1') then
					SW_TRIGGER <= '1';
				elsif((to_integer(unsigned(address)) = (base_addr + ADR_TRIG_MASK_HI))AND N_WR ='1' AND USR_ACCESS = '1') then
					trig_mask(31 downto 16) <= data_in(NBIT_DATAIN-1 downto 0);
				elsif((to_integer(unsigned(address)) = (base_addr + ADR_TRIG_MASK_LO))AND N_WR ='1' AND USR_ACCESS = '1') then
					trig_mask(15 downto 0) <= data_in(NBIT_DATAIN-1 downto 0);
				elsif((to_integer(unsigned(address)) = (base_addr + ADR_PRE_TRIGGER))AND N_WR ='1' AND USR_ACCESS = '1') then
					pre_trigger <= data_in(NBIT_ADDR_SR-1 downto 0);
				elsif((to_integer(unsigned(address)) = (base_addr + ADR_LAST_PTR))AND N_WR ='1' AND USR_ACCESS = '1') then
					last_ptr <= data_in(NBIT_ADDR_MEM-1 downto 0);
				end if;
				
			end if;
			
	end process decode;

end Behavioral;
