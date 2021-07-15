library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity data_mux is
	
   port( clock : in std_logic;
         reset : in std_logic;
         sel_0 : in std_logic;
         data_in_0 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_1 : in std_logic;
         data_in_1 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_2 : in std_logic;
         data_in_2 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_3 : in std_logic;
         data_in_3 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_4 : in std_logic;
         data_in_4 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_5 : in std_logic;
         data_in_5 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_6 : in std_logic;
         data_in_6 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_7 : in std_logic;
         data_in_7 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         sel_8 : in std_logic;
         data_in_8 : in std_logic_vector ( NBIT_DATAIN-1 downto 0);
         --
         data_out : out std_logic_vector (NBIT_DATAOUT-1 downto 0);
         ce_data : in std_logic;
         selector : out std_logic
   );
end data_mux;

architecture behave of data_mux is

begin

 mux_process : process(ce_data,sel_0,sel_1,sel_2,sel_3,sel_4,sel_5,sel_6,sel_7,sel_8,
        data_in_0,data_in_1,data_in_2,data_in_3,data_in_4,data_in_5,data_in_6,data_in_7,data_in_8)
 begin
     selector <= '0';
     if ce_data = '1' then
           if sel_0 = '1' then
              data_out <= data_in_0;
              selector <= '1';
           elsif sel_1 = '1' then
              data_out <= data_in_1;
              selector <= '1';
           elsif sel_2 = '1' then
              data_out <= data_in_2;
              selector <= '1';
           elsif sel_3 = '1' then
              data_out <= data_in_3;
              selector <= '1';
           elsif sel_4 = '1' then
              data_out <= data_in_4;
              selector <= '1';
           elsif sel_5 = '1' then
              data_out <= data_in_5;
              selector <= '1';
           elsif sel_6 = '1' then
              data_out <= data_in_6;
              selector <= '1';
           elsif sel_7 = '1' then
              data_out <= data_in_7;
              selector <= '1';
           elsif sel_8 = '1' then
              data_out <= data_in_8;
              selector <= '1';
           else
              data_out <= (others =>'0');
              selector <= '0';
           end if;
      end if;
   end process;
end behave;

-----------------------------------------------