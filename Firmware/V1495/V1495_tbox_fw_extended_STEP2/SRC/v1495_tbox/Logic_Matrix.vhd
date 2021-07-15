library ieee;
--library vector;                    -- Rende visibile  tutte le funzioni
--use vector.all;          			-- contenute nella libreria "vector".
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.T_SConstants.all;

entity Logic_Matrix is
	
	generic(base_addr: std_logic_vector(NBIT_ADDR-1 downto 0) :=  (others => '0'));
	port(SUBTRG_I : in std_logic_vector(NBIT_SUBTRIG-1 downto 0);
		 TRG_O : out STD_LOGIC_VECTOR(NBIT_TRIG-1 downto 0); 
		 CLK : in STD_LOGIC;
		 RST : in STD_LOGIC;
		 ----------------------------BUS
		 address : in STD_LOGIC_VECTOR(NBIT_ADDR - 1 downto 0);
		 data_in : in STD_LOGIC_VECTOR(NBIT_DATAIN - 1 downto 0);
		 data_out: out STD_LOGIC_VECTOR(NBIT_DATAOUT -1 downto 0);
		 n_rd : in  STD_LOGIC;
		 n_wr : in  STD_LOGIC;
		 USR_ACCESS : in STD_LOGIC;
		 selector: out std_logic    
		 ------------------------------
		 );	 

end Logic_Matrix;


Architecture Behavioral of Logic_Matrix is
	

	
signal compare_to : std_logic_vector(NBIT_LMINPUT - 1 downto 0);
signal reset :std_logic;
type input256_decision_array is array(0 to (NBIT_LMINPUT * NBIT_TRIG - 1) )of std_logic_vector(1 downto 0); ---->  da 0 a 255
signal input256_matcher : input256_decision_array; ---array che raccoglie i valori dei 32 registri di selezione del tipo di ingresso(invertito,bloccato o normale)

type input8_decision_array is array (0 to (nbit_trig- 1)) of std_logic_vector(1 downto 0); ----> da 256 a 263
signal input8_matcher : input8_decision_array;  ---array che raccoglie i valori degli 8 registri di selezione del tipo di uscita finale

type to_or_array_signal is array (0 to Nbit_trig - 1) of std_logic_vector(NBIT_LMINPUT - 1  downto 0);
signal to_or_array : to_or_array_signal;

signal or_output : std_logic_vector(0 to nbit_trig - 1);
	
BEGIN 
	
compare_to <= (others => '0');

	Selection: process(clk,rst,input256_matcher,subtrg_i,to_or_array,compare_to,input8_matcher,or_output)
		begin
				or_input_decisor:for j in nbit_trig-1 downto 0 loop
				
					FOR I IN NBIT_SUBTRIG-1 DOWNTO 0 LOOP 
																				------DA 31 A 0: ciclo che stabilisce che tipo di segnale deve giungere all'or generale dall'input
						case (CONV_INTEGER(input256_matcher((NBIT_LMINPUT*j)+i)))is		------Logica:
							when 1 => to_or_array(j)(i) <= subtrg_i(i);			------01 passa il segnale cos� com'�
							when 2 => to_or_array(j)(i) <= (not subtrg_i(i));	------10 passa il segnale invertito
							when others => to_or_array(j)(i) <= '0';			------00,11 non passa niente
						end case;
					end loop;
					FOR IFEED IN NBIT_TRIG-1 DOWNTO 0 LOOP 
						if(IFEED /= J) then
							case (CONV_INTEGER(input256_matcher((NBIT_LMINPUT*j)+NBIT_SUBTRIG+ifeed)))is		------Logica:
								when 1 => to_or_array(j)(ifeed+NBIT_SUBTRIG) <= or_output(ifeed);			------01 passa il segnale cos� com'�
								when 2 => to_or_array(j)(ifeed+NBIT_SUBTRIG) <= (not or_output(ifeed));	------10 passa il segnale invertito
								when others => to_or_array(j)(ifeed+NBIT_SUBTRIG) <= '0';			------00,11 non passa niente
							end case;
						else
							to_or_array(j)(ifeed+NBIT_SUBTRIG) <= '0';
						end if;
					end loop;
					if(to_or_array(j) = compare_to)	then					---ciclo successivo, confronto tra tutti i segnali con lo std_logic_vector compare_to che contiene solo 0
							or_output(j) <= '0'; 
					else 
							or_output(j) <= '1';
					end if;
				end loop;
				
				
				output_decisor :for i in NBIT_TRIG- 1 downto 0 loop --- DA 7 a 0:ciclo che stabilisce quali segnali andranno all'output
					case (CONV_INTEGER(input8_matcher(i))) is
						when 1 => trg_o(i) <= or_output(i);				----01 passa il segnale cos� com'�
						when 2 => trg_o(i)  <=  not or_output(i);			----10 passa il segnale invertito
						when others => trg_o(i) <= '0';												----00 e 11 non passa niente
					end case;
				
				end loop;
	end process selection;
	
	
	registers: process(clk,rst)
	
		begin
			
			
			if (RST = '1')then
																				-----Reset dei vari array di memorizzazione
				selector <='0';
--				input256_matcher <= ( 35 downto 34 => "01", 1 downto 0 => "10", others =>"00");
--				input8_matcher <= (0 => "10", 1 => "01" , others => "00");
-- mettiamo dei default piu professionali! gab 2010-4-26
				input256_matcher <= (others =>"00");
				input8_matcher <= (others => "00");
				data_out <= (others => '0');
--				for i in ((NBIT_SUBTRIG*NBIT_TRIG)-1) DOWNTO 0 loop	
--					for j in 1 downto 0 loop
--						input256_matcher(i)(j) <='0';
--					end loop;
--				end loop;
--
--				for i in (nbit_trig - 1) DOWNTO 0 loop
--					for j in 1 downto 0 loop
--						input8_matcher(i)(j) <='0';
--					end loop;
--				end loop;
				
			elsif rising_edge(clk)then
				selector <='0';
				
				
								-----Decodifica dell'indirizzo:
				--memoria principale della LM 0x1900 byte ovvero 6400 (1600 registri)
				--Completely changed data storage to extend to 128 inputs
				read_AND_WRITE256: for i in 0 TO NPOS_LM-1 loop			-----Da 0 a 255 scrive o legge sull'input256_matcher a gruppi di 8 elementi per volta
						if((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_RD ='1' 
			                 AND USR_ACCESS = '1') then		
								  read_many: for j in 0 to 7 loop
								      IF(8*I+J<NBIT_LMINPUT*NBIT_TRIG)THEN
											data_out(2*j+1 downto 2*j) <= input256_matcher(8*i+j);
										END IF;
									end loop;
								selector <='1';
						ELSIF ((to_integer(unsigned(address)) = (base_addr+ 2*i))AND N_WR ='1'
			                 AND USR_ACCESS = '1')THEN
								  write_many: for j in 0 to 7 loop
										IF(8*I+J<NBIT_LMINPUT*NBIT_TRIG)THEN
											INPUT256_MATCHER(8*I+j) <= DATA_IN(2*j+1 DOWNTO 2*j);
										end if;
									end loop;
						END IF;
					end loop;
					

-- si lasciano 8192 indirizzi fra input e output (128 input * 32 output * 2 byte)
				read_AND_WRITE8: for i in 0 to (NBIT_TRIG - 1) loop	-----da 0 a 7 scrive o legge sull'input8_matcher{
						if((to_integer(unsigned(address)) = (base_addr+ 8192 + 2*i))AND N_RD ='1' AND USR_ACCESS = '1') then			
							data_out(1 downto 0) <= input8_matcher(i);
							selector <='1';
						ELSIF ((to_integer(unsigned(address)) = (base_addr+ 8192 + 2*i))AND N_WR ='1' AND USR_ACCESS = '1')THEN
							INPUT8_MATCHER(I) <= DATA_IN( 1 DOWNTO 0 );
						END IF;
				end loop;
	end if;
	end process registers;

	
end Behavioral;
