// megafunction wizard: %LPM_COUNTER%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_counter 

// ============================================================
// File Name: simple_counter.v
// Megafunction Name(s):
// 			lpm_counter
//
// Simulation Library Files(s):
// 			lpm
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 9.1 Build 222 10/21/2009 SJ Web Edition
// ************************************************************


//Copyright (C) 1991-2009 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, Altera MegaCore Function License 
//Agreement, or other applicable license agreement, including, 
//without limitation, that your use is for the sole purpose of 
//programming logic devices manufactured by Altera and sold by 
//Altera or its authorized distributors.  Please refer to the 
//applicable agreement for further details.


//lpm_counter DEVICE_FAMILY="APEX20KE" lpm_direction="UP" lpm_port_updown="PORT_UNUSED" lpm_svalue=1 lpm_width=6 clock cnt_en q sclr sset
//VERSION_BEGIN 9.1 cbx_cycloneii 2009:10:21:21:22:16:SJ cbx_lpm_add_sub 2009:10:21:21:22:16:SJ cbx_lpm_compare 2009:10:21:21:22:16:SJ cbx_lpm_counter 2009:10:21:21:22:16:SJ cbx_lpm_decode 2009:10:21:21:22:16:SJ cbx_mgl 2009:10:21:21:37:49:SJ cbx_stratix 2009:10:21:21:22:16:SJ cbx_stratixii 2009:10:21:21:22:16:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463


//synthesis_resources = 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  simple_counter_cntr
	( 
	clock,
	cnt_en,
	q,
	sclr,
	sset) /* synthesis synthesis_clearbox=1 */;
	input   clock;
	input   cnt_en;
	output   [5:0]  q;
	input   sclr;
	input   sset;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1   cnt_en;
	tri0   sclr;
	tri0   sset;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	reg	[6:0]	wire_q_int;

	// synopsys translate_off
	initial
		wire_q_int = 0;
	// synopsys translate_on
	always @(posedge clock)
			if (sclr == 1'b1)	wire_q_int <= 7'b0;
			else
			if (sset == 1'b1)	wire_q_int <= 6'd1;
			else
			if (cnt_en == 1'b1)
				wire_q_int <= wire_q_int[5:0] + 1'b1;
	assign
		q = wire_q_int[5:0];
endmodule //simple_counter_cntr
//VALID FILE


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module simple_counter (
	clock,
	cnt_en,
	sclr,
	sset,
	q)/* synthesis synthesis_clearbox = 1 */;

	input	  clock;
	input	  cnt_en;
	input	  sclr;
	input	  sset;
	output	[5:0]  q;

	wire [5:0] sub_wire0;
	wire [5:0] q = sub_wire0[5:0];

	simple_counter_cntr	simple_counter_cntr_component (
				.sclr (sclr),
				.clock (clock),
				.sset (sset),
				.cnt_en (cnt_en),
				.q (sub_wire0));

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ACLR NUMERIC "0"
// Retrieval info: PRIVATE: ALOAD NUMERIC "0"
// Retrieval info: PRIVATE: ASET NUMERIC "0"
// Retrieval info: PRIVATE: ASET_ALL1 NUMERIC "1"
// Retrieval info: PRIVATE: CLK_EN NUMERIC "0"
// Retrieval info: PRIVATE: CNT_EN NUMERIC "1"
// Retrieval info: PRIVATE: CarryIn NUMERIC "0"
// Retrieval info: PRIVATE: CarryOut NUMERIC "0"
// Retrieval info: PRIVATE: Direction NUMERIC "0"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "APEX20KE"
// Retrieval info: PRIVATE: ModulusCounter NUMERIC "0"
// Retrieval info: PRIVATE: ModulusValue NUMERIC "0"
// Retrieval info: PRIVATE: SCLR NUMERIC "1"
// Retrieval info: PRIVATE: SLOAD NUMERIC "0"
// Retrieval info: PRIVATE: SSET NUMERIC "1"
// Retrieval info: PRIVATE: SSET_ALL1 NUMERIC "0"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "1"
// Retrieval info: PRIVATE: nBit NUMERIC "6"
// Retrieval info: CONSTANT: LPM_DIRECTION STRING "UP"
// Retrieval info: CONSTANT: LPM_PORT_UPDOWN STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: LPM_SVALUE STRING "1"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_COUNTER"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "6"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: USED_PORT: cnt_en 0 0 0 0 INPUT NODEFVAL cnt_en
// Retrieval info: USED_PORT: q 0 0 6 0 OUTPUT NODEFVAL q[5..0]
// Retrieval info: USED_PORT: sclr 0 0 0 0 INPUT NODEFVAL sclr
// Retrieval info: USED_PORT: sset 0 0 0 0 INPUT NODEFVAL sset
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: q 0 0 6 0 @q 0 0 6 0
// Retrieval info: CONNECT: @cnt_en 0 0 0 0 cnt_en 0 0 0 0
// Retrieval info: CONNECT: @sclr 0 0 0 0 sclr 0 0 0 0
// Retrieval info: CONNECT: @sset 0 0 0 0 sset 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.vhd TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.cmp TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter.bsf TRUE FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_inst.vhd TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_waveforms.html TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_wave*.jpg FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL simple_counter_syn.v TRUE
// Retrieval info: LIB_FILE: lpm
