library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    --use work.V2495_pkg.all;
    
USE work.v1495pkg.all;
use work.T_SConstants.all;



entity ID_MANAGER IS
	PORT(
		ID_IN:in std_logic_vector(2 downto 0);
		DATA_IN:in std_logic_vector(31 downto 0);
		SELECT_OUT:out std_logic;
		nEnable_OUT:out std_logic;
		DATA_OUT:out std_logic_vector(31 downto 0)
	);
END ID_MANAGER;

ARCHITECTURE MAIN OF ID_MANAGER IS

SIGNAL PRESENT:std_logic;


BEGIN
	PROCESS(ID_IN) --checking that the board inserted is of the correct type
	BEGIN
		IF(ID_IN="000") THEN
			PRESENT<='1';
		ELSE 
			PRESENT<='0';
		END IF;
	END PROCESS;
	
	PROCESS(PRESENT,DATA_IN) --propagating board input 
	BEGIN
		IF(PRESENT='1') THEN
			DATA_OUT<=DATA_IN;
		ELSE
			DATA_OUT<=(others=>'0');
		END IF;
	END PROCESS;
	
	PROCESS(PRESENT) --setting output pins
	BEGIN
		IF(PRESENT='1') THEN
			SELECT_OUT<='1'; --enabled
			nEnable_OUT<='1'; --input
		ELSE
			SELECT_OUT<='Z';
			nEnable_OUT<='Z';
		END IF;
	END PROCESS;
END MAIN;