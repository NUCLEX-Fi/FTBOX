LIBRARY IEEE;
USE IEEE.Std_Logic_1164.all;
use work.T_SConstants.all;

ENTITY sum128 IS
PORT(a : IN Std_Logic_vector(1 TO NBIT_SUBTRIG);
sum : OUT Std_uLogic_vector(7 downto 0) );
END sum128;

ARCHITECTURE beh4 OF sum128 IS

signal a_ext: std_ulogic_vector (1 to 128);

FUNCTION sum2bits (a : std_ulogic_vector(1 to 2) ) RETURN
std_ulogic_vector IS
VARIABLE s : std_ulogic_vector(1 downto 0);
BEGIN
s(0) := a(1) XOR a(2);
s(1) := a(1) AND a(2);
RETURN s;
END FUNCTION;

FUNCTION sum4bits (a : std_ulogic_vector(1 to 4) ) RETURN
std_ulogic_vector IS
VARIABLE sa, sb : std_ulogic_vector(1 downto 0);
VARIABLE c : std_ulogic;
VARIABLE s : std_ulogic_vector(2 downto 0);
BEGIN
sa := sum2bits(a(1 to 2));
sb := sum2bits(a(3 to 4));
s(0) := sa(0) XOR sb(0);
c := sa(0) AND sb(0);
s(1) := c XOR (sa(1) XOR sb(1));
s(2) := (c AND (sa(1) OR sb(1))) OR (sa(1) and sb(1));
RETURN s;
END FUNCTION;

FUNCTION sum8bits (a : std_ulogic_vector(1 to 8)) RETURN
std_ulogic_vector IS
VARIABLE sa, sb : std_ulogic_vector(2 downto 0);
VARIABLE c : std_ulogic_vector(1 downto 0);
VARIABLE s : std_ulogic_vector(3 downto 0);
BEGIN
sa := sum4bits(a(1 to 4));
sb := sum4bits(a(5 to 8));
s(0) := sa(0) XOR sb(0);
c(0) := sa(0) AND sb(0);
s(1) := c(0) XOR (sa(1) XOR sb(1));
c(1) := (c(0) AND (sa(1) OR sb(1))) OR (sa(1) and sb(1));
s(2) :=  c(1) XOR (sa(2) XOR sb(2));
s(3) := (c(1) AND (sa(2) OR sb(2))) OR (sa(2) and sb(2));
RETURN s;
END FUNCTION;

FUNCTION sum16bits (a : std_ulogic_vector(1 to 16) ) RETURN
std_ulogic_vector IS
VARIABLE sa, sb : std_ulogic_vector(3 downto 0);
VARIABLE c : std_ulogic_vector(2 downto 0);
VARIABLE s : std_ulogic_vector(4 downto 0);
BEGIN
sa := sum8bits(a(1 to 8));
sb := sum8bits(a(9 to 16));
s(0) := sa(0) XOR sb(0);
c(0) := sa(0) AND sb(0);
s(1) := c(0) XOR (sa(1) XOR sb(1));
c(1) := (c(0) AND (sa(1) OR sb(1))) OR (sa(1) and sb(1));
s(2) :=  c(1) XOR (sa(2) XOR sb(2));
c(2) := (c(1) AND (sa(2) OR sb(2))) OR (sa(2) and sb(2));
s(3) :=  c(2) XOR (sa(3) XOR sb(3));
s(4) := (c(2) AND (sa(3) OR sb(3))) OR (sa(3) and sb(3));
RETURN s;
END FUNCTION;

FUNCTION sum32bits (a : std_ulogic_vector(1 to 32) ) RETURN
std_ulogic_vector IS
VARIABLE sa, sb : std_ulogic_vector(4 downto 0);
VARIABLE c : std_ulogic_vector(3 downto 0);
VARIABLE s : std_ulogic_vector(5 downto 0);
BEGIN
sa := sum16bits(a(1 to 16));
sb := sum16bits(a(17 to 32));
s(0) := sa(0) XOR sb(0);
c(0) := sa(0) AND sb(0);
s(1) := c(0) XOR (sa(1) XOR sb(1));
c(1) := (c(0) AND (sa(1) OR sb(1))) OR (sa(1) and sb(1));
s(2) :=  c(1) XOR (sa(2) XOR sb(2));
c(2) := (c(1) AND (sa(2) OR sb(2))) OR (sa(2) and sb(2));
s(3) :=  c(2) XOR (sa(3) XOR sb(3));
c(3) := (c(2) AND (sa(3) OR sb(3))) OR (sa(3) and sb(3));
s(4) :=  c(3) XOR (sa(4) XOR sb(4));
s(5) := (c(3) AND (sa(4) OR sb(4))) OR (sa(4) and sb(4));
RETURN s;
END FUNCTION;

FUNCTION sum64bits (a : std_ulogic_vector(1 to 64) ) RETURN
std_ulogic_vector IS
VARIABLE sa, sb : std_ulogic_vector(5 downto 0);
VARIABLE c : std_ulogic_vector(4 downto 0);
VARIABLE s : std_ulogic_vector(6 downto 0);
BEGIN
sa := sum32bits(a(1 to 32));
sb := sum32bits(a(33 to 64));
s(0) := sa(0) XOR sb(0);
c(0) := sa(0) AND sb(0);
s(1) := c(0) XOR (sa(1) XOR sb(1));
c(1) := (c(0) AND (sa(1) OR sb(1))) OR (sa(1) and sb(1));
s(2) :=  c(1) XOR (sa(2) XOR sb(2));
c(2) := (c(1) AND (sa(2) OR sb(2))) OR (sa(2) and sb(2));
s(3) :=  c(2) XOR (sa(3) XOR sb(3));
c(3) := (c(2) AND (sa(3) OR sb(3))) OR (sa(3) and sb(3));
s(4) :=  c(3) XOR (sa(4) XOR sb(4));
c(4) := (c(3) AND (sa(4) OR sb(4))) OR (sa(4) and sb(4));
s(5) :=  c(4) XOR (sa(5) XOR sb(5));
s(6) := (c(4) AND (sa(5) OR sb(5))) OR (sa(5) and sb(5));
RETURN s;
END FUNCTION;

FUNCTION sum128bits (a : std_ulogic_vector(1 to 128) ) RETURN
std_ulogic_vector IS
VARIABLE sa, sb : std_ulogic_vector(6 downto 0);
VARIABLE c : std_ulogic_vector(5 downto 0);
VARIABLE s : std_ulogic_vector(7 downto 0);
BEGIN
sa := sum64bits(a(1 to 64));
sb := sum64bits(a(65 to 128));
s(0) := sa(0) XOR sb(0);
c(0) := sa(0) AND sb(0);
s(1) := c(0) XOR (sa(1) XOR sb(1));
c(1) := (c(0) AND (sa(1) OR sb(1))) OR (sa(1) and sb(1));
s(2) :=  c(1) XOR (sa(2) XOR sb(2));
c(2) := (c(1) AND (sa(2) OR sb(2))) OR (sa(2) and sb(2));
s(3) :=  c(2) XOR (sa(3) XOR sb(3));
c(3) := (c(2) AND (sa(3) OR sb(3))) OR (sa(3) and sb(3));
s(4) :=  c(3) XOR (sa(4) XOR sb(4));
c(4) := (c(3) AND (sa(4) OR sb(4))) OR (sa(4) and sb(4));
s(5) :=  c(4) XOR (sa(5) XOR sb(5));
c(5) := (c(4) AND (sa(5) OR sb(5))) OR (sa(5) and sb(5));
s(6) :=  c(5) XOR (sa(6) XOR sb(6));
s(7) := (c(5) AND (sa(6) OR sb(6))) OR (sa(6) and sb(6));
RETURN s;
END FUNCTION;


BEGIN
process(a)
begin
	a_ext(1 to NBIT_SUBTRIG)<=to_stdulogicvector(a);
	a_ext(NBIT_SUBTRIG+1 to 128) <= (others =>'0');
end process;

sum <= sum128bits(a_ext);
END ARCHITECTURE beh4;


