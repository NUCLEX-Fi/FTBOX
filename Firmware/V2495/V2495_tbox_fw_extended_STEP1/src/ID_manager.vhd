library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    use work.V2495_pkg.all;
    
USE work.v1495pkg.all;
use work.T_SConstants.all;



entity ID_MANAGER IS
	PORT(
		ID_IN:in std_logic_vector(2 downto 0);
		DATA_IN:inout std_logic_vector(31 downto 0);
		SELECT_OUT:out std_logic;
		nEnable_OUT:out std_logic;
		NIMTTL:in STD_logic;
		CHC:out std_logic_vector(7 downto 0);
		DATA_OUT:out std_logic_vector(31 downto 0)
		
	);
END ID_MANAGER;

ARCHITECTURE MAIN OF ID_MANAGER IS


BEGIN
	
	PROCESS(ID_IN,DATA_IN) --propagating board input 
	BEGIN
		IF(ID_IN="000") THEN
				DATA_OUT<=DATA_IN;
				CHC<=x"20";
		ELSIF(ID_IN="011") THEN
				DATA_OUT(31 downto 8)<=(others=>'0');
				DATA_OUT(0)<=DATA_IN(2);
				DATA_OUT(1)<=DATA_IN(18);
				DATA_OUT(2)<=DATA_IN(3);
				DATA_OUT(3)<=DATA_IN(19);
				DATA_OUT(4)<=DATA_IN(14);
				DATA_OUT(5)<=DATA_IN(30);
				DATA_OUT(6)<=DATA_IN(15);
				DATA_OUT(7)<=DATA_IN(31);
				CHC<=x"08";
		ELSE
			DATA_OUT<=(others=>'0');
			CHC<=x"00";
		END IF;
	END PROCESS;
	
	PROCESS(ID_IN,NIMTTL) --setting output pins
	BEGIN
		IF(ID_IN="000" OR ID_IN="011") THEN
			SELECT_OUT<=NIMTTL; --enabled, NIM LOGIC SELECTED
			nEnable_OUT<='1'; --input
		ELSE
			SELECT_OUT<='Z';
			nEnable_OUT<='Z';
			DATA_IN<=(others=>'Z');
		END IF;
	END PROCESS;
END MAIN;
