//#define MVME5100

#include <stdio.h>
#include <stdlib.h>
//#include <unistd.h>
//#include <strings.h>


#include <TChain.h>
#include <TRootEmbeddedCanvas.h>
#include <TFile.h>
#include <TTimer.h>
#include <TGComboBox.h>
#include <TSelector.h>
#include <TH1F.h>
#include <TLine.h>
#include <TNtuple.h>
#include <TCanvas.h>
#include <TFrame.h>
#include <TApplication.h>
#include <TVirtualPad.h>
#include <TStyle.h>
#include <TObject.h>
#include <TSystem.h>
#include <TThread.h>
class FVmeControl;
class FVmeTrigBox;
// #include "FVmeControl.h"
// #include "FVmeTrigBox.h"
#include "infnfi_tbox.h"
#include "GlobalClasses.h"
//#endif

#define MEM_LEN         0x3000
#define TBOX_BASE_LA    0x4000
#define TBOX_LA         (TBOX_BASE_LA)
#define PRE_TRIGGER     (TBOX_BASE_LA+MEM_LEN)


#define CURRENT_POINTER (TBOX_BASE_LA+MEM_LEN+2)
#define TRIG_POINTER    (TBOX_BASE_LA+MEM_LEN+4) // not used
#define LAST_POINTER    (TBOX_BASE_LA+MEM_LEN+6)
#define MASK_HIGH       (TBOX_BASE_LA+MEM_LEN+8)
#define MASK_LOW        (TBOX_BASE_LA+MEM_LEN+10)

#define CURRENT_POINTER2 (TBOX_BASE_LA+MEM_LEN+4)
#define TRIG_POINTER2    (TBOX_BASE_LA+MEM_LEN+8) // not used
#define LAST_POINTER2    (TBOX_BASE_LA+MEM_LEN+12)
#define MASK_HIGH2       (TBOX_BASE_LA+MEM_LEN+16)
#define MASK_LOW2        (TBOX_BASE_LA+MEM_LEN+20)


//

// questo per riusare la classe MyNumberEntry :)
// #include "TriggerBoxGUI_step.h"

#define NPERSISTENZA 32


class GATriggerBoxLA_step : public TGMainFrame {
public:
  void ExtractSignals();
  void rearm_and_wait();
  void rearm();
  void sw_trigger();
  void wait_trig();
  int data_ready();
  void set_la(unsigned int ptrg, unsigned int length);
  void set_mask(unsigned int mask);
  unsigned int get_mask();
  void get_la( unsigned short *ptr);
  void set_mux(unsigned short val);
  void SetPreTrigger(int ptrg);
  void SetLength(int length);
  void SetExternalTrigger(int extr);
  void Draw();
  //  GATriggerBoxLA();
  GATriggerBoxLA_step(int VMEADDR=0xcff00000,char* suff=NULL,int link=0,int dev=0,unsigned short pretrig=1000/25., 
             unsigned short leng=3000/25., 
             unsigned int tb_mask=0xFFFFFFFF,
             unsigned short tb_mux=8, int tb_nsignals=32,
		int tb_ext_trigger=0);
  ~GATriggerBoxLA_step(){};

  void TrigBoardModel();
  
  int TrigBoardData();
  /*{
	  return (int)(tbox->ReadReg(INFNFI_BOARD_DATA));
//       *(unsigned short *)(la+INFNFI_BOARD_FWDATA));
  }*/


  int TrigBoardOrder();
//   {
// 	  return (int)(tbox->ReadReg(INFNFI_TBOX_ORD));
// //       *(unsigned short *)(la+INFNFI_TBOX_ORD));
//   }
//   
  void MyTimer();
  void Changed();
  void RearmChanged();

  virtual void CloseWindow()
    {
      printf("\n\n*** BYE BYE ***\n\n");
      exit(-1);
    }

 protected:
  TRootEmbeddedCanvas *ecanv;

  TriggerBoxSettings set;
  unsigned short pretrig;
  unsigned short len; 
  unsigned int mask;
  unsigned short mux;
  int is_V2495;
  int tauclk;
  int nsignals;
  int ext_trigger;
  //  FSignal *sigs[32];
  TH1F *sigs[NPERSISTENZA][32];
  unsigned char *la;
  FVmeControl *vme;
  FVmeTrigBox *tbox;
  TLine *pt;

  TGComboBox *combo_mux;
  MyNumberEntry* viewlen, *pretrigger;

  TGCheckButton *triggeron_main;
  TGCheckButton *triggeron_input[128];

  TGTextButton *button_enable;

  TString nomi_input[ 128 ];
  TString nomi_output[ 32 ];
  TString nomi_output_fin[ 32];
  TString nomi_output_ord[ 32];
  TLatex nomi_assey[ 128+32 ];
  TLatex trigger_status;
  int current_event;
  ClassDef(GATriggerBoxLA_step,0)
};


//GATriggerBoxLA_step::GATriggerBoxLA_step()
//{
//  GATriggerBoxLA_step::GATriggerBoxLA_step(128,1024,0xFFFFFFFF,2,32,0);
//}
