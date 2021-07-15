-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: V1495USR_DEMO
-- Device:          ALTERA EP1C4F400C6
-- Author:          Luca Colombini
-- Date:            02-03-2006
-- ----------------------------------------------------------------------------
-- Module:          V1495USR_PKG
-- Description:     Package that implements global constants (ID Codes, 
--                  Register Addresses).
-- ****************************************************************************

-- ############################################################################
-- Revision History:
-- ############################################################################
LIBRARY ieee;
USE ieee.std_logic_1164.all;
PACKAGE v1495pkg IS
   
-- Constants
-- Expansion Mezzanine Type ID-Codes (111 means no mezzanine)
constant A395A : std_logic_vector(2 downto 0) := "000"; -- 32CH IN LVDS/ECL INTERFACE
constant A395B : std_logic_vector(2 downto 0) := "001"; -- 32CH OUT LVDS INTERFACE
constant A395C : std_logic_vector(2 downto 0) := "010"; -- 32CH OUT ECL INTERFACE
constant A395D : std_logic_vector(2 downto 0) := "011"; -- 8CH I/O SELECT NIM/TTL INTER
constant A395E : std_logic_vector(2 downto 0) := "100"; -- 8CH 16bit +-5V DAC


END v1495pkg;
