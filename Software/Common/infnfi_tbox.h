
#define		CAEN_ASTATUS_L  	0x1000
#define		CAEN_ASTATUS_H  	0x1002 
#define		CAEN_BSTATUS_L  	0x1004 
#define		CAEN_BSTATUS_H  	0x1006 
#define		CAEN_CSTATUS_L  	0x1008 
#define		CAEN_CSTATUS_H  	0x100A 
#define		CAEN_AMASK_L    	0x100C 
#define		CAEN_AMASK_H    	0x100E 
#define		CAEN_BMASK_L    	0x1010 
#define 	CAEN_BMASK_H    	0x1012 
#define 	CAEN_CMASK_L    	0x1014 
#define 	CAEN_CMASK_H    	0x1016 
#define 	CAEN_GATEWIDTH  	0x1018 
#define 	CAEN_CCTRL_L    	0x101A 
#define 	CAEN_CCTRL_H    	0x101C 
#define 	CAEN_MODE       	0x101E // bit 0=(1->Trigger Box, 0->Coinc.Register)
#define 	CAEN_SCRATCH    	0x1020 
#define 	CAEN_GCTRL      	0x1022 // bit 0=(1->NIM positive logic, 0->TTL)
#define 	CAEN_DCTRL_L    	0x1024 
#define 	CAEN_DCTRL_H    	0x1026 
#define 	CAEN_DDATA_L    	0x1028 
#define 	CAEN_DDATA_H    	0x102A 
#define 	CAEN_ECTRL_L    	0x102C 
#define 	CAEN_ECTRL_H    	0x102E 
#define 	CAEN_EDATA_L    	0x1030 
#define 	CAEN_EDATA_H    	0x1032 
#define 	CAEN_FCTRL_L    	0x1034 
#define 	CAEN_FCTRL_H    	0x1036 
#define 	CAEN_FDATA_L    	0x1038 
#define 	CAEN_FDATA_H    	0x103A 
#define 	CAEN_REVISION   	0x103C 
#define 	CAEN_PDL_CTRL   	0x103E 
#define 	CAEN_PDL_DATA   	0x1040 
#define 	CAEN_DIDCODE    	0x1042 
#define 	CAEN_EIDCODE    	0x1044 
#define 	CAEN_FIDCODE    	0x1046 
///************************************************
#define		INFNFI_TBOX_NSUBTRIG   32
#define		INFNFI_TBOX_NTRIG   8
#define		INFNFI_TBOX_CTRL	0x1090	/*(LSNibble=Debug Mux, bit15->Software Reset)*/
#define  	INFNFI_TBOX_ORD 0x1088 //Ordering of outputs
#define		INFNFI_TBOX_SETVETO	0x1092	/*  writing to this register sets the VETO signal */
#define		INFNFI_TBOX_RESETVETO	0x1094	/*  writing to this register resets the VETO signal */
#define		INFNFI_TBOX_RESETIRQ	0x1096	/*  writing to this register resets the IRQ signal */
//
#define		INFNFI_TBOX_GDGEN_DEL	0x1100	/* Gate and Delay generator (resolving time) DELAY base addr (up to 128 input)*/
#define		INFNFI_TBOX_GDGEN_WID	0x1200	/* Gate and Delay Generator (resolving time) WIDTH */
//
#define		INFNFI_TBOX_LMINPUT	0x1400	/*Logic Matrix input registers base addr (128 inputs X 32 outputs)*/
#define     	INFNFI_TBOX_LM_MULTINPUT 0x3300    /*masks for multiplicity triggers*/
//
// WARNING: this map for LM does not correspond to the present situation. Now we have 32+8 inputs (8 for trigger feedback)
// so that EQ0 goes from 0x1400 to 0x144E and EQ1 starts at 0x1450 and so on up to 0x1680
//
// #define		INFNFI_TBOX_LMINPUT0	0x1400	/*Logic Matrix input registers EQ0 base addr*/
// #define		INFNFI_TBOX_LMINPUT1	0x1500	/*Logic Matrix input registers EQ1 base addr*/
// #define		INFNFI_TBOX_LMINPUT2	0x1600	/*Logic Matrix input registers EQ2 base addr*/
// #define		INFNFI_TBOX_LMINPUT3	0x1700	/*Logic Matrix input registers EQ3 base addr*/
// #define		INFNFI_TBOX_LMINPUT4	0x1800	/*Logic Matrix input registers EQ4 base addr*/
// #define		INFNFI_TBOX_LMINPUT5	0x1900	/*Logic Matrix input registers EQ5 base addr*/
// #define		INFNFI_TBOX_LMINPUT6	0x1A00	/*Logic Matrix input registers EQ6 base addr*/
// #define		INFNFI_TBOX_LMINPUT7	0x1B00	/*Logic Matrix input registers EQ7 base addr*/
// #define		INFNFI_TBOX_LMINPUT8	0x1C00	/*Logic Matrix input registers EQ8 base addr*/
// #define		INFNFI_TBOX_LMINPUT9	0x1D00	/*Logic Matrix input registers EQ9 base addr*/
// #define		INFNFI_TBOX_LMINPUT10	0x1E00	/*Logic Matrix input registers EQ10 base addr*/
// #define		INFNFI_TBOX_LMINPUT11	0x1F00	/*Logic Matrix input registers EQ11 base addr*/
// #define		INFNFI_TBOX_LMINPUT12	0x2000	/*Logic Matrix input registers EQ12 base addr*/
// #define		INFNFI_TBOX_LMINPUT13	0x2100	/*Logic Matrix input registers EQ13 base addr*/
// #define		INFNFI_TBOX_LMINPUT14	0x2200	/*Logic Matrix input registers EQ14 base addr*/
// #define		INFNFI_TBOX_LMINPUT15	0x2300	/*Logic Matrix input registers EQ15 base addr*/
// #define		INFNFI_TBOX_LMINPUT16	0x2400	/*Logic Matrix input registers EQ16 base addr*/
// #define		INFNFI_TBOX_LMINPUT17	0x2500	/*Logic Matrix input registers EQ17 base addr*/
// #define		INFNFI_TBOX_LMINPUT18	0x2600	/*Logic Matrix input registers EQ18 base addr*/
// #define		INFNFI_TBOX_LMINPUT19	0x2700	/*Logic Matrix input registers EQ19 base addr*/
// #define		INFNFI_TBOX_LMINPUT20	0x2800	/*Logic Matrix input registers EQ20 base addr*/
// #define		INFNFI_TBOX_LMINPUT21	0x2900	/*Logic Matrix input registers EQ21 base addr*/
// #define		INFNFI_TBOX_LMINPUT22	0x2A00	/*Logic Matrix input registers EQ22 base addr*/
// #define		INFNFI_TBOX_LMINPUT23	0x2B00	/*Logic Matrix input registers EQ23 base addr*/
// #define		INFNFI_TBOX_LMINPUT24	0x2C00	/*Logic Matrix input registers EQ24 base addr*/
// #define		INFNFI_TBOX_LMINPUT25	0x2D00	/*Logic Matrix input registers EQ25 base addr*/
// #define		INFNFI_TBOX_LMINPUT26	0x2E00	/*Logic Matrix input registers EQ26 base addr*/
// #define		INFNFI_TBOX_LMINPUT27	0x2F00	/*Logic Matrix input registers EQ27 base addr*/
// #define		INFNFI_TBOX_LMINPUT28	0x3000	/*Logic Matrix input registers EQ28 base addr*/
// #define		INFNFI_TBOX_LMINPUT29	0x3100	/*Logic Matrix input registers EQ29 base addr*/
// #define		INFNFI_TBOX_LMINPUT30	0x3200	/*Logic Matrix input registers EQ30 base addr*/
// #define		INFNFI_TBOX_LMINPUT31	0x3300	/*Logic Matrix input registers EQ31 base addr*/
//
#define		INFNFI_TBOX_LMOUTPUT	0x3400  /* Logic Matrix output registers */
//
// #define		INFNFI_TBOX_LMOUTPUT0	0x3400  /* Logic Matrix output register EQ0 */
// #define		INFNFI_TBOX_LMOUTPUT1	0x3402  /* Logic Matrix output register EQ1 */
// #define		INFNFI_TBOX_LMOUTPUT2	0x3404  /* Logic Matrix output register EQ2 */
// #define		INFNFI_TBOX_LMOUTPUT3	0x3406  /* Logic Matrix output register EQ3 */
// #define		INFNFI_TBOX_LMOUTPUT4	0x3408  /* Logic Matrix output register EQ4 */
// #define		INFNFI_TBOX_LMOUTPUT5	0x340A  /* Logic Matrix output register EQ5 */
// #define		INFNFI_TBOX_LMOUTPUT6	0x340C  /* Logic Matrix output register EQ6 */
// #define		INFNFI_TBOX_LMOUTPUT7	0x340E  /* Logic Matrix output register EQ7 */
// #define		INFNFI_TBOX_LMOUTPUT8	0x3410  /* Logic Matrix output register EQ8 */
// #define		INFNFI_TBOX_LMOUTPUT9	0x3412  /* Logic Matrix output register EQ9 */
// #define		INFNFI_TBOX_LMOUTPUT10	0x3414  /* Logic Matrix output register EQ10 */
// #define		INFNFI_TBOX_LMOUTPUT11	0x3416  /* Logic Matrix output register EQ11 */
// #define		INFNFI_TBOX_LMOUTPUT12	0x3418  /* Logic Matrix output register EQ12 */
// #define		INFNFI_TBOX_LMOUTPUT13	0x341A  /* Logic Matrix output register EQ13 */
// #define		INFNFI_TBOX_LMOUTPUT14	0x341C  /* Logic Matrix output register EQ14 */
// #define		INFNFI_TBOX_LMOUTPUT15	0x341E  /* Logic Matrix output register EQ15 */
// #define		INFNFI_TBOX_LMOUTPUT16	0x3420  /* Logic Matrix output register EQ16*/
// #define		INFNFI_TBOX_LMOUTPUT17	0x3422  /* Logic Matrix output register EQ17*/
// #define		INFNFI_TBOX_LMOUTPUT18	0x3424  /* Logic Matrix output register EQ18*/
// #define		INFNFI_TBOX_LMOUTPUT19	0x3426  /* Logic Matrix output register EQ19*/
// #define		INFNFI_TBOX_LMOUTPUT20	0x3428  /* Logic Matrix output register EQ20*/
// #define		INFNFI_TBOX_LMOUTPUT21	0x342A  /* Logic Matrix output register EQ21*/
// #define		INFNFI_TBOX_LMOUTPUT22	0x342C  /* Logic Matrix output register EQ22*/
// #define		INFNFI_TBOX_LMOUTPUT23	0x342E  /* Logic Matrix output register EQ23 */
// #define		INFNFI_TBOX_LMOUTPUT24	0x3430  /* Logic Matrix output register EQ24 */
// #define		INFNFI_TBOX_LMOUTPUT25	0x3432  /* Logic Matrix output register EQ25 */
// #define		INFNFI_TBOX_LMOUTPUT26	0x3434  /* Logic Matrix output register EQ26 */
// #define		INFNFI_TBOX_LMOUTPUT27	0x3436  /* Logic Matrix output register EQ27 */
// #define		INFNFI_TBOX_LMOUTPUT28	0x3438  /* Logic Matrix output register EQ28 */
// #define		INFNFI_TBOX_LMOUTPUT29	0x343A  /* Logic Matrix output register EQ29 */
// #define		INFNFI_TBOX_LMOUTPUT30	0x343C  /* Logic Matrix output register EQ30 */
// #define		INFNFI_TBOX_LMOUTPUT31	0x343E  /* Logic Matrix output register EQ31 */
//
#define		INFNFI_TBOX_RED_MASK 	0x3440	/* Reduction down scaler base addr */
#define		INFNFI_TBOX_REDUCTION	0x3450	/* Reduction down scaler base addr */
//
#define		INFNFI_TBOX_BITPATTERN	0x3490 /* bit pattern register */
#define		INFNFI_TBOX_TRIG_REST	0x3492 /* bit pattern and main trigger resolving time */
#define		INFNFI_TBOX_TRIGMASK	0x3494	/* trigger mask register */
#define		INFNFI_TBOX_AUTORST_PAT	0x3496	/* bit0=1 enable bit pat reset after serial TX */
// 
//
// WARNING: counters are now 32-bit (not 16 as in Giordano's original project); there is only room for 16 triggers between 0x3510 and 0x3550!!
//
#define		INFNFI_TBOX_SCALE0	0x3510	/*scaler 0 (pre veto) base addr (up to 32 triggers...NO! 16) */
#define		INFNFI_TBOX_SCALE1	0x3550	/*scaler 1 (post veto) base addr (up to 32 triggers...NO! 16) */
#define		INFNFI_TBOX_SCALE2	0x3590	/*scaler 2 (post reduction) base addr  (up to 32 triggers...NO! 16) */

#define		INFNFI_TBOX_MAINTR_WID	0x3600	/* Main Trigger output width in 25ns units */
#define		INFNFI_TBOX_MAINTR_DEL	0x3602	/* validation delay with respecto to Main Trigger */
#define         INFNFI_VME_CTRL         0x8000  /* choose RORA or ROAK mode */
#define         INFNFI_VME_INT_LEVEL    0x8004  /* interrupt level  */
#define         INFNFI_VME_INT_VECT     0x8006  /* interrupt vector */
// to distinguish between 1495 and 2495
#define         INFNFI_BOARD2           0x8134  /* always 0 */
#define         INFNFI_BOARD1           0x8138  /* 1495=5  2495=9 */
#define         INFNFI_BOARD0           0x813C  /* 1495=0xD7 2495=0xBF  */
#define         INFNFI_BOARD_MODEL      0x1080  /* either 1495 or 2495  */
#define         INFNFI_BOARD_DATA      0x1084  /* either 1495 or 2495  */


//************************************************
// ADDRESS MAP FOR TBOX ON V2495. REGISTERS ARE NOW ALIGNED ON 32bit BOUNDARIES
//************************************************
#define		INFNFI2_TBOX_NSUBTRIG   32
#define		INFNFI2_TBOX_NTRIG   8
#define		INFNFI2_TBOX_CTRL	0x1090	/*(LSNibble=Debug Mux, bit15->Software Reset)*/
#define		INFNFI2_TBOX_SETVETO	0x1094	/*  writing to this register sets the VETO signal */
#define		INFNFI2_TBOX_RESETVETO	0x1098	/*  writing to this register resets the VETO signal */
#define		INFNFI2_TBOX_RESETIRQ	0x109C	/*  writing to this register resets the IRQ signal */
//
#define		INFNFI2_TBOX_GDGEN_DEL	0x1100	/* Gate and Delay generator (resolving time) DELAY base addr (up to 64 input)*/
#define		INFNFI2_TBOX_GDGEN_WID	0x1200	/* Gate and Delay Generator (resolving time) WIDTH */
//
#define		INFNFI2_TBOX_LMINPUT	0x1400	/*Logic Matrix input registers base addr */
//

//
#define		INFNFI2_TBOX_LMOUTPUT	0x3400  /* Logic Matrix output registers */
//

//
#define		INFNFI2_TBOX_RED_MASK 	0x3440	/* Reduction down scaler base addr */
#define		INFNFI2_TBOX_REDUCTION	0x3450	/* Reduction down scaler base addr */
//
#define		INFNFI2_TBOX_BITPATTERN	0x3490 /* bit pattern register */
#define		INFNFI2_TBOX_TRIG_REST	0x3494 /* bit pattern and main trigger resolving time */
#define		INFNFI2_TBOX_TRIGMASK	0x3498	/* trigger mask register */
#define		INFNFI2_TBOX_AUTORST_PAT	0x349C	/* bit0=1 enable bit pat reset after serial TX */
// 
//
// WARNING: counters are now 32-bit (not 16 as in Giordano's original project); there is only room for 16 triggers between 0x3510 and 0x3550!!
//
#define		INFNFI2_TBOX_SCALE0	0x3510	/*scaler 0 (pre veto) base addr (up to 32 triggers...NO! 16) */
#define		INFNFI2_TBOX_SCALE1	0x3550	/*scaler 1 (post veto) base addr (up to 32 triggers...NO! 16) */
#define		INFNFI2_TBOX_SCALE2	0x3590	/*scaler 2 (post reduction) base addr  (up to 32 triggers...NO! 16) */

#define		INFNFI2_TBOX_MAINTR_WID	0x3600	/* Main Trigger output width in 25ns units */
#define		INFNFI2_TBOX_MAINTR_DEL	0x3604	/* validation delay with respecto to Main Trigger */
#define         INFNFI2_VME_CTRL         0x8000  /* choose RORA or ROAK mode */
#define         INFNFI2_VME_INT_LEVEL    0x8008  /* interrupt level  */
#define         INFNFI2_VME_INT_VECT     0x800C  /* interrupt vector */








