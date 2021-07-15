library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    use work.V2495_pkg.all;
    
USE work.v1495pkg.all;
use work.T_SConstants.all;




entity trigcode_generator is
port(
	increment : in std_logic;
	reset : in std_logic;
	valout : out std_logic_vector(15 downto 0)
);
end 	trigcode_generator;



architecture RTL of Trigcode_generator is

signal codicenow : std_logic_vector(15 downto 0);
signal codicenext : std_logic_vector(15 downto 0);
signal trebits : std_logic_vector(2 downto 0);


begin

trebits<=codicenow(15 downto 13);

codicenext(15 downto 1)<=codicenow(14 downto 0);
codicenext(0)<=not((trebits(0) xor trebits(1)) xor trebits(2));
valout<=codicenow;

process(reset,increment,codicenext)
begin	
	if reset='1' then
		codicenow<=(others=>'0');
	elsif rising_edge(increment) then
		codicenow<=codicenext;
	end if;
end process;

end architecture RTL;