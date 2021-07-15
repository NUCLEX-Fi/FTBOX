/*
  $Header: /home/CVS/luigi/FClasses/FVmeTrigBox.h,v 1.25 2019/05/14 11:08:48 bini Exp $
  $Log: FVmeTrigBox.h,v $
  Revision 1.25  2019/05/14 11:08:48  bini
  Added function to select connector for output trigger

  Revision 1.24  2019-05-13 16:34:18  bini
  Added functions to FVmeTrigBox to read/write register for reordering
  output triggers. Added method to select input logic for A395D
  mezzanine (V2495 only)

  Revision 1.23  2019-04-09 14:34:29  bini
  Added function for low level access to TRIGGER box registers (read mode)

  Revision 1.22  2019-03-06 09:16:01  bini
  Added a metrhod to read FW information from register 0x1084 in new FW

  Revision 1.21  2019-03-04 16:37:30  bini
  Corrected bugs in FVmeTrigBox.cxx and FVmeTrigBox.h

  Revision 1.20  2019-03-04 14:18:01  bini
  Minor changes in Trigger Box related files

  Revision 1.19  2019-03-01 11:33:49  bini
  Added functions for wrtiting to the memory of the new v2495 firmware with extended number of inputs (128)

  Revision 1.18  2018-07-13 10:14:28  bini
  FVmeTrigBox: Bug fixed in Init(), now we keep other bits untouched

  Revision 1.17  2018-07-05 15:21:52  bini
  few changes from short to int for 2495 card

  Revision 1.16  2018-07-03 14:38:48  bini
  FVmeTrigBox constructor now calls TrigBoxModel() to determine CAEN
  board model automatically.

  Revision 1.15  2018-07-02 07:45:44  garfield
  FVmeTrigBox: modified to work also with V2495

  Revision 1.14  2018-06-19 15:07:45  bini
  Added IRQ handlling via 0x1096 register (writing to this register
  clears interrupt request signals in TBox user fpga).

  Revision 1.13  2018-06-05 07:46:20  garfield
  FVmeTrigBox: Added method to set output trigger (validation) delay.

  Revision 1.12  2017-07-14 14:24:19  bini
  *** empty log message ***

  Revision 1.11  2017-05-16 12:32:53  bini
  0x1000 subtracted for Legnaro Trigger Box, window1 size adapted for 7100

  Revision 1.10  2015-07-08 15:03:15  bini
  new trig select function, few errors corrected

  Revision 1.9  2013-09-23 16:19:32  bini
  with Bo card control

  Revision 1.8  2010/11/16 13:36:45  bini
  working version with new driver: new DMA initialization with window 7
  statically created at boot time

  Revision 1.7  2010/09/17 10:53:17  bini
  all vme classes MVME5100 6100 7100 compatible with new universe-tsi148
  driver

  Revision 1.6  2010/06/14 11:13:08  bini
  Aggiunto metodo Init()

  Revision 1.5  2010/06/11 17:00:36  bini
  Aggiunta gestione registro per abilitare reset automatico
  del bit pattern dopo la trasmissione seriale (per FAIR)

  Revision 1.4  2010/06/10 15:36:51  bini
  Aggiunto metodo SetOutputWidth(int val) per gestione larghezza main trigger
  della T Box

  Revision 1.3  2010/06/09 16:59:25  bini
  Nuova versione FVmeTrigBox con lettura scalers a 32bit

  Revision 1.2  2010/05/31 05:50:57  bini
  new reset bit pattern function

  Revision 1.1  2010/04/26 10:25:02  bini
  Nuova scheda trigger box VHDL gabriele
  fix vari

 
*/

/*********** CHECK FOR VME CPUs!!! **************/
#if defined (MVME5100) || defined (MVME2400) || defined (MVME6100) || defined (MVME7100) || defined (CAEN_VME_BRIDGE)
/************************************************/

#include <math.h>
#include <stdlib.h>     
#include <unistd.h>

#include <errno.h>
#include <unistd.h>

#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <vector>
#include <fcntl.h>

#ifndef NOROOT

#include "TObject.h"
#include "TH1.h"
#include "TF1.h"
#include "TFile.h"
#include "TCanvas.h"
#include "TRandom.h"
#include "TVirtualPad.h"
#include "TPad.h"
#include "TLine.h"
#include "TText.h"
#include "TArray.h" 
#include "TArrayI.h" 
#include "TString.h"

#endif
 
//#define LEGNARO     // comment if TRIGBOX REG start with 0x1000 


#ifndef FIASCO_FVmeTrigBox
#define FIASCO_FVmeTrigBox

#include "FVmeControl.h"

// #include <FVmeDsp.h>

#ifndef NOROOT
class FVmeTrigBox: public TObject{
#else
class FVmeTrigBox{
#endif

#define BOARD_SIZE  0x10000

public: 
  FVmeTrigBox(){};
  
  FVmeTrigBox(unsigned int vmead, FVmeControl *ctrl, int is_V2495=0){
    int trigbox_reg;
    this->ctrl=ctrl;
#ifndef CAEN_VME_BRIDGE
    if(!(board_addr=(char *)ctrl->VmeMapMem(BOARD_SIZE,vmead))){
        printf("%s  ERROR: Unable to map memory\n",__PRETTY_FUNCTION__);
    }
#else
    board_addr= (uint32_t)vmead;
#endif
    
#ifdef LEGNARO
#warning  ===========ATTENZIONE === TRIGBOX REG starting 0x0000 ==========
#warning 
#warning TRIGBOX REG start with 0x0000
    board_addr-= 0x1000;
    trigbox_reg=0;
#else
#warning TRIGBOX REG start with 0x1000
    trigbox_reg=0x1000;
#endif

#ifndef CAEN_VME_BRIDGE
    fdvme=ctrl->Getvme_handle();
    phys_addr=vmead;
#endif

    TrigBoardModel();
    if(IsV2495())
         bytes_per_reg = 4;
    else
         bytes_per_reg = 2;

    printf("bytes_per_reg=%d\n",bytes_per_reg);
    //   Init();  //TrigBox Reset
   };

virtual  ~FVmeTrigBox(){
#ifndef CAEN_VME_BRIDGE
    ctrl->VmeUnmapMem(BOARD_SIZE, (unsigned int)board_addr);
#endif
     };

#ifndef CAEN_VME_BRIDGE
  char * GetBoardAddr() { return board_addr;};
#else
  uint32_t GetBoardAddr() { return board_addr;};
#endif
  
  int IsV2495() { return is_V2495;};
#ifndef CAEN_VME_BRIDGE
  int fdvme;
  unsigned int phys_addr;
#endif
  FVmeControl *ctrl;
  int is_V2495;  
  int bytes_per_reg;
  
  
  int GetNScale();
  unsigned short GetBitPattern();
  void ResetBitPattern();
  unsigned short GetTrigRest();
  unsigned short GetTrigMask();
  unsigned short ReadRegister(int Address);
  int SetTrigMask(unsigned short mask);
  std::vector<unsigned int> *GetScalePreVeto(std::vector<unsigned int> *s);
  std::vector<unsigned int> *GetScalePostVeto(std::vector<unsigned int> *s);
  std::vector<unsigned int> *GetScalePostReduction(std::vector<unsigned int> *s);
  void SetLMIn(int subtrg, int trg, int val);
  int GetGeneralFWData();
  void SetOutputOrder_STEP(int Order);
  int GetOuputOrder_STEP();
  void SetA395DLogic(int nimTTL);
  void SetOutputConnector_STEP(int select);
  void SetLMIn_128_STEP1(int ind,int tot_count,int *val);
  void SetMultiplicityMask_128_STEP1(int ind,int tot_count,int *val);
  void SetLMIn_128_STEP2(int ind,int tot_count,int *val);
  void SetLMOut(int trg, int val);
  void SetInWidth(int val);
  void SetInDelay(int subtrg, int val);
  void SetInDelay_128_STEP2(int subtrg, int val1, int val2);
  void SetTrigReduction(int trg, int val);
  void SetTrigResTime(int val);
  void SetOutputWidth(int val);
  void SetOutputDelay(int val);
  void SetBitPatAutoReset(int val);
  void SetTrigMaskBit(int trig, int val);
  void SetFportLevel(int);
  void SetMux(int val);
  void ResetScale();
  void SetVeto();
  void ResetVeto();
  void ResetIrq();
  unsigned short EnableIrq();
  unsigned short DisableIrq();
  unsigned short EnableIntVeto();
  unsigned short DisableIntVeto();
  void SetVMECtrlReg(int val);
  int  SetVMEIntLevel(int val);
  void DisableVMEInt();
  void SetVMEIntVect(int val);
  void Init();
  void TrigBoardModel();
  
  void SetOutLogic(int logic);
  void SetForcedVeto(int val);
  void ResetCodeGenerator();
  
  
unsigned short ReadReg(int regaddr);
void WriteReg (int regaddr,unsigned short Value);
    
unsigned int ReadRegInt(int regaddr);
void WriteRegInt(int regaddr,unsigned int Value);

protected:
//read/write operation
#ifndef CAEN_VME_BRIDGE    
  char * board_addr;
#else
  uint32_t board_addr;
#endif

#ifndef NOROOT
  ClassDef(FVmeTrigBox,1) // FIASCO: Class for storing and manipulating ADC events
#endif
};

/***************************************************************************/
#endif




#endif /* end of #if defined (MVME5100) || defined (MVME2400) */
