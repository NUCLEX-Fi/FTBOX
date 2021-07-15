library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    use work.V2495_pkg.all;
    
USE work.v1495pkg.all;
use work.T_SConstants.all;



entity OUT_MANAGER IS
 Port ( 
		OUTPUT_SIG : in STD_LOGIC_VECTOR(31 downto 0);
		OUTPUT_OUT : out STD_LOGIC_VECTOR(31 downto 0);
		ORDER : in STD_LOGIC_VECTOR(15 downto 0)
		);
 end OUT_MANAGER;
 
 ARCHITECTURE MAIN of OUT_MANAGER IS
 BEGIN
	
PROCESS(OUTPUT_SIG,ORDER)
BEGIN
	for I in 0 to 3 LOOP
		case (ORDER(4*i+3 downto 4*i)) is
			when x"A"=>
				OUTPUT_OUT(8*i+7 downto 8*i)<=OUTPUT_SIG(7 downto 0);
			when x"B"=>
				OUTPUT_OUT(8*i+7 downto 8*i)<=OUTPUT_SIG(15 downto 8);
			when x"C"=>
				OUTPUT_OUT(8*i+7 downto 8*i)<=OUTPUT_SIG(23 downto 16);
			when x"D"=>
				OUTPUT_OUT(8*i+7 downto 8*i)<=OUTPUT_SIG(31 downto 24);
			when others=>
				OUTPUT_OUT(8*i+7 downto 8*i)<=(others=>'0');
		end case;
	end loop;
END PROCESS;
 
 
 
 
 
 
 
 
 END MAIN;