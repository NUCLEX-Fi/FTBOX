/*
<<<<<<< FVmeTrigBox.cxx
  $Header: /home/CVS/luigi/FClasses/FVmeTrigBox.cxx,v 1.24 2019/05/14 11:08:48 bini Exp $
=======
  $Header: /home/CVS/luigi/FClasses/FVmeTrigBox.cxx,v 1.24 2019/05/14 11:08:48 bini Exp $
>>>>>>> 1.21
  $Log: FVmeTrigBox.cxx,v $
  Revision 1.24  2019/05/14 11:08:48  bini
  Added function to select connector for output trigger

  Revision 1.23  2019-05-13 16:34:18  bini
  Added functions to FVmeTrigBox to read/write register for reordering
  output triggers. Added method to select input logic for A395D
  mezzanine (V2495 only)

  Revision 1.22  2019-04-09 14:34:29  bini
  Added function for low level access to TRIGGER box registers (read mode)

<<<<<<< FVmeTrigBox.cxx
  Revision 1.20  2019-03-06 09:16:01  bini
  Added a metrhod to read FW information from register 0x1084 in new FW

=======
  Revision 1.21  2019-03-13 17:06:16  bini
  Minor modifications

  Revision 1.20  2019-03-06 09:16:01  bini
  Added a metrhod to read FW information from register 0x1084 in new FW

>>>>>>> 1.21
  Revision 1.19  2019-03-04 16:37:30  bini
  Corrected bugs in FVmeTrigBox.cxx and FVmeTrigBox.h

  Revision 1.18  2019-03-04 14:18:01  bini
  Minor changes in Trigger Box related files

  Revision 1.17  2019-03-01 11:33:49  bini
  Added functions for wrtiting to the memory of the new v2495 firmware with extended number of inputs (128)

  Revision 1.16  2018-07-13 10:14:28  bini
  FVmeTrigBox: Bug fixed in Init(), now we keep other bits untouched

  Revision 1.15  2018-07-05 15:21:52  bini
  few changes from short to int for 2495 card

  Revision 1.14  2018-07-03 14:38:48  bini
  FVmeTrigBox constructor now calls TrigBoxModel() to determine CAEN
  board model automatically.

  Revision 1.13  2018-07-02 07:45:44  garfield
  FVmeTrigBox: modified to work also with V2495

  Revision 1.12  2018-06-19 15:07:45  bini
  Added IRQ handlling via 0x1096 register (writing to this register
  clears interrupt request signals in TBox user fpga).

  Revision 1.11  2018-06-05 07:46:20  garfield
  FVmeTrigBox: Added method to set output trigger (validation) delay.

  Revision 1.10  2017-07-14 14:24:19  bini
  *** empty log message ***

  Revision 1.9  2013-09-23 16:19:32  bini
  with Bo card control

  Revision 1.8  2010/09/17 10:53:17  bini
  all vme classes MVME5100 6100 7100 compatible with new universe-tsi148
  driver

  Revision 1.7  2010/06/14 11:13:08  bini
  Aggiunto metodo Init()

  Revision 1.6  2010/06/11 17:00:36  bini
  Aggiunta gestione registro per abilitare reset automatico
  del bit pattern dopo la trasmissione seriale (per FAIR)

  Revision 1.5  2010/06/10 15:36:51  bini
  Aggiunto metodo SetOutputWidth(int val) per gestione larghezza main trigger
  della T Box

  Revision 1.4  2010/06/09 16:59:25  bini
  Nuova versione FVmeTrigBox con lettura scalers a 32bit

  Revision 1.3  2010/05/31 05:50:57  bini
  new reset bit pattern function

  Revision 1.2  2010/04/26 10:47:41  bini
  Fix in ResetScale

  Revision 1.1  2010/04/26 10:25:02  bini
  Nuova scheda trigger box VHDL gabriele
  fix vari


*/


/*********** CHECK FOR VME CPUs!!! **************/
#if defined (MVME5100) || defined (MVME2400) || defined (MVME6100) || defined (MVME7100) || defined (CAEN_VME_BRIDGE)
/************************************************/

// 
//=======================
//////////////////////////////////////////////////////////////////////////
//                                                                     
//                                                                     
//////////////////////////////////////////////////////////////////////////
#include "FVmeTrigBox.h"
#include "infnfi_tbox.h"

#ifndef NOROOT
ClassImp(FVmeTrigBox);
#endif
//Generic RW operation
unsigned short FVmeTrigBox::ReadReg(int regaddr){
#ifndef CAEN_VME_BRIDGE
    return (*(unsigned short *)(board_addr+regaddr));
#else
    return ctrl->vmebridge_readshort((uint32_t)(board_addr+regaddr));
#endif
}

void FVmeTrigBox::WriteReg(int regaddr,unsigned short Value){
#ifndef CAEN_VME_BRIDGE
    *(unsigned short *)(board_addr+regaddr)=Value;
#else
    ctrl->vmebridge_writeshort((uint32_t)(board_addr+regaddr),Value);
#endif
}

unsigned int FVmeTrigBox::ReadRegInt(int regaddr){
#ifndef CAEN_VME_BRIDGE
    return (*(unsigned int *)(board_addr+regaddr));
#else
    return ctrl->vmebridge_readint((uint32_t)(board_addr+regaddr));
#endif
}

void FVmeTrigBox::WriteRegInt(int regaddr,uint32_t Value){
#ifndef CAEN_VME_BRIDGE
    *(unsigned int *)(board_addr+regaddr)=Value;
#else
    ctrl->vmebridge_writeint((uint32_t)(board_addr+regaddr),Value);
#endif
}

/***************************************************************************/
 void FVmeTrigBox::TrigBoardModel()
  { 
    unsigned short bm=ReadReg(INFNFI_BOARD_MODEL);
    if(bm == 2495)
      is_V2495=1;
    else if(bm == 1495)
      is_V2495=0;
    else 
    	is_V2495=0;
    printf("v2495=%d\n",is_V2495);
  };


unsigned short FVmeTrigBox::GetBitPattern()
{
    if(is_V2495)
        return ReadReg(INFNFI2_TBOX_BITPATTERN);
//         *(unsigned short *)(board_addr+INFNFI2_TBOX_BITPATTERN);
    else
        return ReadReg(INFNFI_TBOX_BITPATTERN);
//         *(unsigned short *)(board_addr+INFNFI_TBOX_BITPATTERN);
}

void FVmeTrigBox::ResetBitPattern()
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_BITPATTERN,1);
//         *(unsigned short *)(board_addr+INFNFI2_TBOX_BITPATTERN)=1;
    else
            WriteReg(INFNFI_TBOX_BITPATTERN,1);
        //         *(unsigned short *)(board_addr+INFNFI_TBOX_BITPATTERN)=1;
}

unsigned short FVmeTrigBox::GetTrigRest()
{
        if(is_V2495)
            return ReadReg(INFNFI2_TBOX_TRIG_REST);
//             return *(unsigned short *)(board_addr+INFNFI2_TBOX_TRIG_REST);
        else
            return ReadReg(INFNFI_TBOX_TRIG_REST);
//             return *(unsigned short *)(board_addr+INFNFI_TBOX_TRIG_REST);
}


unsigned short FVmeTrigBox::GetTrigMask()
{
    if(is_V2495)
        return ReadReg(INFNFI2_TBOX_TRIGMASK);
//         return *(unsigned short *)(board_addr+INFNFI2_TBOX_TRIGMASK);
    else
        return ReadReg(INFNFI_TBOX_TRIGMASK);
//         return *(unsigned short *)(board_addr+INFNFI_TBOX_TRIGMASK);
}

unsigned short FVmeTrigBox::ReadRegister(int address){
    return ReadReg(address);
// 	return *(unsigned short *)(board_addr+address);	
}

int FVmeTrigBox::SetTrigMask(unsigned short mask)
{
    
    if(is_V2495)
        WriteReg(INFNFI2_TBOX_TRIGMASK,mask);
//        *(unsigned short *)(board_addr+INFNFI2_TBOX_TRIGMASK)=mask;
    else
        WriteReg(INFNFI_TBOX_TRIGMASK,mask);
//         *(unsigned short *)(board_addr+INFNFI_TBOX_TRIGMASK)=mask;
    
  return 0;
}

#define N_SCALE 8

int FVmeTrigBox::GetNScale()
{
  return N_SCALE;
}

//RIVEDERE....

std::vector<unsigned int>* FVmeTrigBox::GetScalePreVeto(std::vector<unsigned int> *s)
{
    if(s==NULL)
     s= new std::vector<unsigned int>();
   else
     s->clear();
   if(is_V2495)
   {
#ifndef CAEN_VME_BRIDGE
        unsigned int *buf=(unsigned int *)(board_addr+INFNFI2_TBOX_SCALE0);
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
             s->push_back(buf[n_s]);
#else
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(ReadRegInt(INFNFI2_TBOX_SCALE0+bytes_per_reg*n_s));
#endif
   }
   else
   {
#ifndef CAEN_VME_BRIDGE
        unsigned short *buf=(unsigned short *)(board_addr+INFNFI_TBOX_SCALE0);
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(buf[n_s*2]*65536+buf[n_s*2+1]);
#else
         for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(ReadReg(INFNFI_TBOX_SCALE0+bytes_per_reg*2*n_s)*65536+ReadReg(INFNFI_TBOX_SCALE0+bytes_per_reg*(2*n_s+1)));        
#endif
   }
   return s;
}

std::vector<unsigned int>*  FVmeTrigBox::GetScalePostVeto(std::vector<unsigned int>* s)
{
   if(s==NULL)
     s= new std::vector<unsigned int>();
   else
     s->clear();
   if(is_V2495)
   {
#ifndef CAEN_VME_BRIDGE
        unsigned int *buf=(unsigned int *)(board_addr+INFNFI2_TBOX_SCALE1);
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
             s->push_back(buf[n_s]);
#else
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(ReadRegInt(INFNFI2_TBOX_SCALE1+bytes_per_reg*n_s));
#endif
   }
   else
   {
#ifndef CAEN_VME_BRIDGE
        unsigned short *buf=(unsigned short *)(board_addr+INFNFI_TBOX_SCALE1);
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(buf[n_s*2]*65536+buf[n_s*2+1]);
#else
         for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(ReadReg(INFNFI_TBOX_SCALE1+bytes_per_reg*2*n_s)*65536+ReadReg(INFNFI_TBOX_SCALE1+bytes_per_reg*(2*n_s+1)));        
#endif
   }
   return s;
}

std::vector<unsigned int>*   FVmeTrigBox::GetScalePostReduction(std::vector<unsigned int>* s)
{
   if(s==NULL)
     s= new std::vector<unsigned int>();
   else
     s->clear();
   if(is_V2495)
   {
#ifndef CAEN_VME_BRIDGE
        unsigned int *buf=(unsigned int *)(board_addr+INFNFI2_TBOX_SCALE2);
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
             s->push_back(buf[n_s]);
#else
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(ReadRegInt(INFNFI2_TBOX_SCALE2+bytes_per_reg*n_s));
#endif
   }
   else
   {
#ifndef CAEN_VME_BRIDGE
        unsigned short *buf=(unsigned short *)(board_addr+INFNFI_TBOX_SCALE2);
        for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(buf[n_s*2]*65536+buf[n_s*2+1]);
#else
         for (int n_s = 0; n_s < N_SCALE ; n_s++)
            s->push_back(ReadReg(INFNFI_TBOX_SCALE2+bytes_per_reg*2*n_s)*65536+ReadReg(INFNFI_TBOX_SCALE2+bytes_per_reg*(2*n_s+1)));        
#endif
   }
   return s;
}
//FINO QUI
void FVmeTrigBox::ResetScale()
{
  unsigned short val=ReadReg(INFNFI_TBOX_CTRL);// same address for  V1495 and V2495
//   unsigned short val=*(unsigned short *)(board_addr+INFNFI_TBOX_CTRL); // same address for  V1495 and V2495
  val |= (1<<6);
  WriteReg(INFNFI_TBOX_CTRL,val);
//   *(unsigned short *)(board_addr+INFNFI_TBOX_CTRL)= val;
  usleep(100000);
  val &= (~(1<<6));
  WriteReg(INFNFI_TBOX_CTRL,val);
//   *(unsigned short *)(board_addr+INFNFI_TBOX_CTRL)=    val;
}

void FVmeTrigBox::Init()
{
    if(!is_V2495){
     /* set CAEN mode to Trigger Box mode */
             WriteReg(CAEN_MODE,0);
//             *((unsigned short *)(board_addr+CAEN_MODE))=0;
      /* set CAEN G_PORT level to NIM (positive logic) */
             WriteReg(CAEN_GCTRL,1);
            *((unsigned short *)(board_addr+CAEN_GCTRL))=1;
            usleep(100000);
    }
      /* reset Trigger Box */
            unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | 0x80;
            WriteReg(INFNFI_TBOX_CTRL,vreg);
           // *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=0x80;  // same address for  V1495 and V2495
            usleep(100000);
            vreg=ReadReg(INFNFI_TBOX_CTRL) & (~0x80);
            WriteReg(INFNFI_TBOX_CTRL,vreg);
           // *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~0x80);  // same address for  V1495 and V2495
            usleep(100000);
}

unsigned short FVmeTrigBox::EnableIrq() // bit 9  on: TrigBox will generate interrupts 
{
  unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<9);
  WriteReg(INFNFI_TBOX_CTRL,vreg);
  //*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=(1<<9);
  return vreg;
  //return *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL));
}
unsigned short FVmeTrigBox::EnableIntVeto() // bit 8  on: TrigBox will handle internal veto
{
  unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<8);
  WriteReg(INFNFI_TBOX_CTRL,vreg);
//   *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=(1<<8);
  return vreg;
//   return *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL));

}
unsigned short FVmeTrigBox::DisableIrq() // bit 9  on: TrigBox will generate interrupts 
{
  unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<9));
  WriteReg(INFNFI_TBOX_CTRL,vreg); 
  //*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~(1<<9));
  return vreg;
//   return *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL));

}
unsigned short FVmeTrigBox::DisableIntVeto() // bit 8  on: TrigBox will handle internal veto
{
    unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<8));
    WriteReg(INFNFI_TBOX_CTRL,vreg); 
//   *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~(1<<8));
    return vreg;
//   return *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL));

}

void FVmeTrigBox::SetLMIn(int subtrg, int trg, int val)
{
    WriteReg(INFNFI_TBOX_LMINPUT+bytes_per_reg*((INFNFI_TBOX_NSUBTRIG+INFNFI_TBOX_NTRIG)*trg+subtrg),val);
//   *((unsigned short *)(board_addr+INFNFI_TBOX_LMINPUT+bytes_per_reg*((INFNFI_TBOX_NSUBTRIG+INFNFI_TBOX_NTRIG)*trg+subtrg)))=val;   // same address for  V1495 and V2495
}

int FVmeTrigBox::GetGeneralFWData(){
    int res=(int)ReadReg(INFNFI_BOARD_DATA);
// 	int res=(int)(*(unsigned short *)(board_addr+INFNFI_BOARD_DATA));
	return res;	
}

void FVmeTrigBox::SetOutputOrder_STEP(int Order){
  //build number
	if(is_V2495){
        WriteReg(INFNFI_TBOX_ORD,Order);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_ORD))=Order;   // same address for  V1495 and V2495
	}
}


int FVmeTrigBox::GetOuputOrder_STEP(){
	if(is_V2495){
		int res=(int)ReadReg(INFNFI_TBOX_ORD);
//         int res=(int)(*(unsigned short *)(board_addr+INFNFI_TBOX_ORD));
		return res;	
	}
	return 0;
}
  
void FVmeTrigBox::SetA395DLogic(int nimTTL){
	if(nimTTL){
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<10);
        WriteReg(INFNFI_TBOX_CTRL,vreg);
		//*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=(1<<10);
	}
	else{
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<10));
        WriteReg(INFNFI_TBOX_CTRL,vreg);
		//*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~(1<<10));
	}
}

void FVmeTrigBox::SetOutputConnector_STEP(int select){
	if(select){
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<4);
        WriteReg(INFNFI_TBOX_CTRL,vreg);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=(1<<4);
	}
	else{
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<4));
        WriteReg(INFNFI_TBOX_CTRL,vreg);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~(1<<4));
	}
}

void FVmeTrigBox::SetOutLogic(int logic){
    if(is_V2495==0) return;
	if(logic){
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<13);
        WriteReg(INFNFI_TBOX_CTRL,vreg);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=(1<<4);
	}
	else{
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<13));
        WriteReg(INFNFI_TBOX_CTRL,vreg);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~(1<<4));
	}
}


void FVmeTrigBox::SetForcedVeto(int val){
    if(is_V2495==0) return;
	if(val){
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<14);
        WriteReg(INFNFI_TBOX_CTRL,vreg);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))|=(1<<4);
	}
	else{
        unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<14));
        WriteReg(INFNFI_TBOX_CTRL,vreg);
// 		*((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))&=(~(1<<4));
	}
}


void FVmeTrigBox::ResetCodeGenerator(){
    if(is_V2495==0) return;
	unsigned short vreg=ReadReg(INFNFI_TBOX_CTRL) | (1<<15);
    WriteReg(INFNFI_TBOX_CTRL,vreg);
    usleep(10000);
    vreg=ReadReg(INFNFI_TBOX_CTRL) & (~(1<<15));
    WriteReg(INFNFI_TBOX_CTRL,vreg);
    usleep(10000);    
}

void FVmeTrigBox::SetLMIn_128_STEP2(int ind, int tot_count, int *val)
{
  //build number
  int qval=0;
  for(int i=0;i<tot_count;i++) qval=qval | ((val[i] & 0x3)<<(2*i));
  WriteReg(INFNFI_TBOX_LMINPUT+bytes_per_reg*ind,qval);
//   *((unsigned short *)(board_addr+INFNFI_TBOX_LMINPUT+bytes_per_reg*ind))=qval;   // same address for  V1495 and V2495
}

void FVmeTrigBox::SetLMIn_128_STEP1(int ind, int tot_count, int *val)
{
  //build number
  int qval=0;
  for(int i=0;i<tot_count;i++) qval=qval | ((val[i] & 0x1)<<(i));
  WriteReg(INFNFI_TBOX_LMINPUT+bytes_per_reg*ind,qval);
//   *((unsigned short *)(board_addr+INFNFI_TBOX_LMINPUT+bytes_per_reg*ind))=qval;   // same address for  V1495 and V2495
}

void FVmeTrigBox::SetMultiplicityMask_128_STEP1(int ind,int tot_count,int *val){
  //build number
  int qval=0;
  for(int i=0;i<tot_count;i++) qval=qval | ((val[i] & 0x1)<<(i));
  WriteReg(INFNFI_TBOX_LM_MULTINPUT+bytes_per_reg*ind,qval);
//   *((unsigned short *)(board_addr+INFNFI_TBOX_LM_MULTINPUT+bytes_per_reg*ind))=qval;   // same address for  V1495 and V2495
}

void FVmeTrigBox::SetLMOut(int trg, int val)
{
  WriteReg(INFNFI_TBOX_LMOUTPUT+bytes_per_reg*trg,val);
//  *((unsigned short *)(board_addr+INFNFI_TBOX_LMOUTPUT+bytes_per_reg*trg))=val;   // same address for  V1495 and V2495

}

void FVmeTrigBox::SetInWidth(int val)
{
    WriteReg(INFNFI_TBOX_GDGEN_WID,val);
// 	*((unsigned short *)(board_addr+INFNFI_TBOX_GDGEN_WID))=val;
}

void FVmeTrigBox::SetInDelay(int subtrg, int val)
{
     WriteReg(INFNFI_TBOX_GDGEN_DEL+bytes_per_reg*subtrg,val);
// 	*((unsigned short *)(board_addr+INFNFI_TBOX_GDGEN_DEL+bytes_per_reg*subtrg))=val;  // same address for  V1495 and V2495
}

void FVmeTrigBox::SetInDelay_128_STEP2(int subtrg, int val1,int val2)
{
	if(subtrg % 2!=0){
		 printf("Invalid subtrg value, only even values are accepted\n");
		return;
	}
	int qval=(val1 & 0x3F) | ((val2 & 0x3F)<<8);
    WriteReg(INFNFI_TBOX_GDGEN_DEL+bytes_per_reg*(subtrg>>1),qval);
// 	*((unsigned short *)(board_addr+INFNFI_TBOX_GDGEN_DEL+bytes_per_reg*(subtrg>>1)))=qval;  // same address for  V1495 and V2495
}

void FVmeTrigBox::SetTrigReduction(int trg, int val)
{
    WriteReg(INFNFI_TBOX_REDUCTION+bytes_per_reg*trg,val);
// 	*((unsigned short *)(board_addr+INFNFI_TBOX_REDUCTION+bytes_per_reg*trg))=val;   // same address for  V1495 and V2495
}

void FVmeTrigBox::SetTrigResTime(int val)
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_TRIG_REST,val);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_TRIG_REST))=val;
    else
            WriteReg(INFNFI_TBOX_TRIG_REST,val);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_TRIG_REST))=val;
}

void FVmeTrigBox::SetOutputDelay(int val)
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_MAINTR_DEL,val);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_MAINTR_DEL))=val;
    else
             WriteReg(INFNFI_TBOX_MAINTR_DEL,val);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_MAINTR_DEL))=val;
}

void FVmeTrigBox::SetOutputWidth(int val)
{
     WriteReg(INFNFI_TBOX_MAINTR_WID,val);
// 	*((unsigned short *)(board_addr+INFNFI_TBOX_MAINTR_WID))=val;  // same address
}
void FVmeTrigBox::SetVeto()
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_SETVETO,1);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_SETVETO))=1;
    else
            WriteReg(INFNFI_TBOX_SETVETO,1);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_SETVETO))=1;
}
void FVmeTrigBox::ResetVeto()
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_RESETVETO,1);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_RESETVETO))=1;
    else
            WriteReg(INFNFI_TBOX_RESETVETO,1);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_RESETVETO))=1;
}

void FVmeTrigBox::ResetIrq()
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_RESETIRQ,1);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_RESETIRQ))=1;
    else
            WriteReg(INFNFI_TBOX_RESETIRQ,1);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_RESETIRQ))=1;
}

void FVmeTrigBox::SetFportLevel(int val)  // ATTENZIONE!!! DA IMPLENTARE PER LA V2595
{
    if(!is_V2495){
        /* bit 0 =1 means NIMfor A395D mezzanine =0 means TTL */
        unsigned short vreg=ReadReg(CAEN_FCTRL_L) | (val &1);
        WriteReg(CAEN_FCTRL_L,vreg);
//         *((unsigned short *)(board_addr+CAEN_FCTRL_L))|=(val&1);
                    usleep(100000);
    }
}

// set bit 0 to 1 to enable auto reset:
void FVmeTrigBox::SetBitPatAutoReset(int val)
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_AUTORST_PAT,val);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_AUTORST_PAT))=val;
    else
            WriteReg(INFNFI_TBOX_AUTORST_PAT,val);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_AUTORST_PAT))=val;
}

void FVmeTrigBox::SetTrigMaskBit(int trig, int val)
{
    if(is_V2495){
        unsigned short old=ReadReg(INFNFI2_TBOX_RED_MASK);
//         unsigned short old=*((unsigned short *)(board_addr+INFNFI2_TBOX_RED_MASK));
        old &= (~(1<<trig)); // ora e' spento
        if(val!=0)
        old |= (1<<trig); // acceso
        WriteReg(INFNFI2_TBOX_RED_MASK,old);
//         *((unsigned short *)(board_addr+INFNFI2_TBOX_RED_MASK)) = old;
    }
    else{
        unsigned short old=ReadReg(INFNFI_TBOX_RED_MASK);
//         unsigned short old=*((unsigned short *)(board_addr+INFNFI_TBOX_RED_MASK));
        old &= (~(1<<trig)); // ora e' spento
        if(val!=0)
        old |= (1<<trig); // acceso
         WriteReg(INFNFI_TBOX_RED_MASK,old);
//         *((unsigned short *)(board_addr+INFNFI_TBOX_RED_MASK)) = old;
    }
}

void FVmeTrigBox::SetMux(int val)
{
    if(is_V2495)
            WriteReg(INFNFI2_TBOX_CTRL,val);
//             *((unsigned short *)(board_addr+INFNFI2_TBOX_CTRL))=val;
    else
            WriteReg(INFNFI_TBOX_CTRL,val);
//             *((unsigned short *)(board_addr+INFNFI_TBOX_CTRL))=val;
}

void FVmeTrigBox::SetVMECtrlReg(int val)
{ /* 0 RORA mod int must be removed via 0 on VMEIntLevel
     1 ROAK is removed on acknowledge  
     >1  is interpreted as 1  */
     if(is_V2495){
          unsigned int currval = ReadRegInt(INFNFI2_VME_CTRL);
//             unsigned int currval = *((unsigned int *)(board_addr+INFNFI2_VME_CTRL));
            if(!val)
                WriteRegInt(INFNFI2_VME_CTRL,(0xFFFFFFFE & currval));
//                 *((unsigned int *)(board_addr+INFNFI2_VME_CTRL)) =(0xFFFFFFFE & currval);
            else
                WriteRegInt(INFNFI2_VME_CTRL,(currval | 1));
//                 *((unsigned int *)(board_addr+INFNFI2_VME_CTRL))=(currval | 1);        
     }else{
            unsigned short currval = ReadReg(INFNFI_VME_CTRL);
//             unsigned short currval = *((unsigned short *)(board_addr+INFNFI_VME_CTRL));
            if(!val)
                WriteReg(INFNFI_VME_CTRL,(0xFFFE & currval));
//                 *((unsigned short *)(board_addr+INFNFI_VME_CTRL)) =(0xFFFE & currval);
            else
                 WriteReg(INFNFI_VME_CTRL,(currval | 1));
//                 *((unsigned short *)(board_addr+INFNFI_VME_CTRL))=(currval | 1);        
     }
}

int FVmeTrigBox::SetVMEIntLevel(int val)
{ /* 0 means interrupt disabled
     1-7 int level enabled             */
  if(val<1 || val>7) return -1;
  if(is_V2495){
        unsigned int lev=ReadRegInt(INFNFI2_VME_INT_LEVEL) & 0xFFF8;
        WriteRegInt(INFNFI2_VME_INT_LEVEL,lev|val);
//         unsigned int lev=(*((unsigned int *)(board_addr+INFNFI2_VME_INT_LEVEL)))&0xFFF8;
//         *((unsigned int *)(board_addr+INFNFI2_VME_INT_LEVEL))=(lev|val);
  }else{
      unsigned short lev=ReadReg(INFNFI_VME_INT_LEVEL) & 0xfff8;
        WriteReg(INFNFI_VME_INT_LEVEL,lev|val);
//         unsigned short lev=(*((unsigned short *)(board_addr+INFNFI_VME_INT_LEVEL)))&0xFFF8;
//         *((unsigned short *)(board_addr+INFNFI_VME_INT_LEVEL))=(lev|val);
  }
  return 0;
}

void FVmeTrigBox::DisableVMEInt()
{ /* 0  int level = 0  */
    if(is_V2495){
        unsigned int vreg=ReadRegInt(INFNFI2_VME_INT_LEVEL) &  (0xFFFFFFF8);
        WriteRegInt(INFNFI2_VME_INT_LEVEL,vreg);
    }
//         *((unsigned int *)(board_addr+INFNFI2_VME_INT_LEVEL))&= (0xFFFFFFF8);
    else{
        unsigned short vreg=ReadReg(INFNFI_VME_INT_LEVEL) &  (0xFFF8);
        WriteReg(INFNFI_VME_INT_LEVEL,vreg);
    }
//         *((unsigned short *)(board_addr+INFNFI_VME_INT_LEVEL))&= (0xFFF8);
}

void FVmeTrigBox::SetVMEIntVect(int val)
{ /* interrupt vector value*/
    if(is_V2495)
        WriteRegInt(INFNFI2_VME_INT_VECT,val);
//         *((unsigned int *)(board_addr+INFNFI2_VME_INT_VECT))=val;
    else
        WriteReg(INFNFI_VME_INT_VECT,val);
//         *((unsigned short *)(board_addr+INFNFI_VME_INT_VECT))=val;
}


#endif /* end of #if defined (MVME5100) || defined (MVME2400)  || defined (MVME6100) || defined (MVME7100) */
