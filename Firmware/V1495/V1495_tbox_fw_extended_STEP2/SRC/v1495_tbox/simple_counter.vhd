-- megafunction wizard: %LPM_COUNTER%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: lpm_counter 

-- ============================================================
-- File Name: simple_counter.vhd
-- Megafunction Name(s):
-- 			lpm_counter
--
-- Simulation Library Files(s):
-- 			lpm
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 9.1 Build 222 10/21/2009 SJ Web Edition
-- ************************************************************


--Copyright (C) 1991-2009 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY lpm;
USE lpm.all;

ENTITY simple_counter IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		cnt_en		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		sset		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
END simple_counter;


ARCHITECTURE SYN OF simple_counter IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (5 DOWNTO 0);



	COMPONENT lpm_counter
	GENERIC (
		lpm_direction		: STRING;
		lpm_port_updown		: STRING;
		lpm_svalue		: STRING;
		lpm_type		: STRING;
		lpm_width		: NATURAL
	);
	PORT (
			sclr	: IN STD_LOGIC ;
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
			sset	: IN STD_LOGIC ;
			cnt_en	: IN STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	q    <= sub_wire0(5 DOWNTO 0);

	lpm_counter_component : lpm_counter
	GENERIC MAP (
		lpm_direction => "UP",
		lpm_port_updown => "PORT_UNUSED",
		lpm_svalue => "1",
		lpm_type => "LPM_COUNTER",
		lpm_width => 6
	)
	PORT MAP (
		sclr => sclr,
		clock => clock,
		sset => sset,
		cnt_en => cnt_en,
		q => sub_wire0
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: ACLR NUMERIC "0"
-- Retrieval info: PRIVATE: ALOAD NUMERIC "0"
-- Retrieval info: PRIVATE: ASET NUMERIC "0"
-- Retrieval info: PRIVATE: ASET_ALL1 NUMERIC "1"
-- Retrieval info: PRIVATE: CLK_EN NUMERIC "0"
-- Retrieval info: PRIVATE: CNT_EN NUMERIC "1"
-- Retrieval info: PRIVATE: CarryIn NUMERIC "0"
-- Retrieval info: PRIVATE: CarryOut NUMERIC "0"
-- Retrieval info: PRIVATE: Direction NUMERIC "0"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "APEX20KE"
-- Retrieval info: PRIVATE: ModulusCounter NUMERIC "0"
-- Retrieval info: PRIVATE: ModulusValue NUMERIC "0"
-- Retrieval info: PRIVATE: SCLR NUMERIC "1"
-- Retrieval info: PRIVATE: SLOAD NUMERIC "0"
-- Retrieval info: PRIVATE: SSET NUMERIC "1"
-- Retrieval info: PRIVATE: SSET_ALL1 NUMERIC "0"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "1"
-- Retrieval info: PRIVATE: nBit NUMERIC "6"
-- Retrieval info: CONSTANT: LPM_DIRECTION STRING "UP"
-- Retrieval info: CONSTANT: LPM_PORT_UPDOWN STRING "PORT_UNUSED"
-- Retrieval info: CONSTANT: LPM_SVALUE STRING "1"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_COUNTER"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "6"
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: cnt_en 0 0 0 0 INPUT NODEFVAL cnt_en
-- Retrieval info: USED_PORT: q 0 0 6 0 OUTPUT NODEFVAL q[5..0]
-- Retrieval info: USED_PORT: sclr 0 0 0 0 INPUT NODEFVAL sclr
-- Retrieval info: USED_PORT: sset 0 0 0 0 INPUT NODEFVAL sset
-- Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: q 0 0 6 0 @q 0 0 6 0
-- Retrieval info: CONNECT: @cnt_en 0 0 0 0 cnt_en 0 0 0 0
-- Retrieval info: CONNECT: @sclr 0 0 0 0 sclr 0 0 0 0
-- Retrieval info: CONNECT: @sset 0 0 0 0 sset 0 0 0 0
-- Retrieval info: LIBRARY: lpm lpm.lpm_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.bsf TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_inst.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_waveforms.html TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_wave*.jpg FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_syn.v TRUE
-- Retrieval info: LIB_FILE: lpm