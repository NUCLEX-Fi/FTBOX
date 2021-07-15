library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    
USE work.v1495pkg.all;
use work.T_SConstants.all;



entity ID_OUT_MANAGER IS
	PORT(
		ID_IN:in std_logic_vector(2 downto 0);
		DATA_IN:in std_logic_vector(31 downto 0);
		SELECT_OUT:out std_logic;
		nEnable_OUT:out std_logic;
		DATA_OUT:out std_logic_vector(31 downto 0)
	);
END ID_OUT_MANAGER;

ARCHITECTURE MAIN OF ID_OUT_MANAGER IS



BEGIN
	PROCESS(DATA_IN,ID_IN) --propagating board input 
	BEGIN
		DATA_OUT<=(others=>'0');
		IF(ID_IN="011") THEN
			DATA_OUT(0)<=DATA_IN(31);
			DATA_OUT(1)<=DATA_IN(30);
			DATA_OUT(2)<=DATA_IN(29);
			DATA_OUT(3)<=DATA_IN(28);
			DATA_OUT(4)<=DATA_IN(27);
			DATA_OUT(5)<=DATA_IN(26);
			DATA_OUT(6)<=DATA_IN(25);
			DATA_OUT(7)<=DATA_IN(24);			
		ELSIF ID_IN="010" THEN
			DATA_OUT<=DATA_IN;
		ELSE
			DATA_OUT<=(others=>'0');
		END IF;
	END PROCESS;
	
	PROCESS(ID_IN) --setting output pins
	BEGIN
		IF(ID_IN="011" OR ID_IN="010") THEN
			SELECT_OUT<='1'; --enabled nim
			nEnable_OUT<='0'; --output
		ELSE
			SELECT_OUT<='1';
			nEnable_OUT<='0';
			--DATA_IN<=(others=>'Z');
		END IF;
	END PROCESS;
END MAIN;