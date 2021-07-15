/*
  files utilizzati:
  acq.rc --> nomi dei canali di out
  trgboxnames.rc -> nomi dei canali di in
  triggerboxgui_pars.txt -> memoria del setup CORRENTE: 
  da non toccare per nussun motivo
  *.trg : files di configurazione "utente" in cui salvare le varie configurazioni

*/
/*#define STEP_1
#ifdef STEP_1
	#define DEFAULT_SAVE_FILE "triggerboxgui_pars_step1.txt"
#else
	#define DEFAULT_SAVE_FILE "triggerboxgui_pars_step2.txt"
#endif*/


#include <cstdio>
#include <cstdlib>
#include <string>
#include <fstream>
#include <sstream>

#include "GlobalClasses.h"


#include <TApplication.h>
#include <TGFrame.h>
#include <TGTableLayout.h>
#include <TGComboBox.h>
#include <TGButton.h>
#include <TGLabel.h>
#include <TGTab.h>
#include <TGNumberEntry.h>
#include <TROOT.h>
#include <TGMenu.h>
#include <TCanvas.h>
#include <TLatex.h>
#include <TString.h>
#include <TObjString.h>
#include <TObjArray.h>
#include <TGFileDialog.h>
#include <TGMsgBox.h>


class FVmeControl;
class FVmeTrigBox;

// #include "FVmeControl.h"
// #include "FVmeTrigBox.h"


#define GUI_OR  " + "
#define GUI_NOT " - "
#define GUI_X   "   "
#define GUI_ACTIVE " v " 
#define GUI_PASS  " => "
#define GUI_VETO  " | "

/*
class TriggerBoxSettings{
	public:
		int nSeries_Mtrig;
		int nOutputs;
		int nRealInputs;
		int nFeedback;
		int nInputs_LM;
		int nOutputs_LM;
		int VME_ADDR;
		int STEP;
		TString Default_Save_File;	
		TString ACQ_RC_name;
		TString trigbox_name;
		TString output_gen;
		
		TriggerBoxSettings(){
			nSeries_Mtrig=0;
			nOutputs=8;
			nRealInputs=32;
			nFeedback=8;
			nInputs_LM=40;
			nOutputs_LM=nOutputs;
			VME_ADDR=0xcff00000;
			STEP=2;
			Default_Save_File=TString("triggerboxgui_pars.txt");
			ACQ_RC_name=TString("acq.rc");
			trigbox_name=TString("trgboxnames.rc");
			output_gen=TString("gen_outputs.rc");
		}
		
		void SetData(int VME_adr,int TBData,TString suff){
			STEP=TBData & 0x3;
			VME_ADDR=VME_adr;
			nSeries_Mtrig=(TBData>>2) & 0x3;
			nRealInputs=(TBData>>4) & 0x7F;
			if(nRealInputs==0) nRealInputs=128;
			nOutputs=(TBData>>11) & 0x1F;
			if(nOutputs==0) nOutputs=32;
			TString base=TString("");
			if(STEP==1) base=TString("SubTriggerBox/");
			Default_Save_File=base+TString("triggerboxgui_pars")+suff+TString(".trg");
			ACQ_RC_name=base+TString("acq")+suff+TString(".rc");
			trigbox_name=base+TString("trgboxnames")+suff+TString(".rc");
			output_gen=base+TString("gen_outputs")+suff+TString(".rc");
			if(STEP==1) nFeedback=0;
			else nFeedback=nOutputs;
			
			if(STEP==1) nOutputs_LM=nOutputs+nSeries_Mtrig;
			else nOutputs_LM=nOutputs;
			
			if(STEP==1) nInputs_LM=nRealInputs;
			else nInputs_LM=nRealInputs+nFeedback;
			
			printf("VME_ADDR=%x\n",VME_ADDR);
			printf("STEP=%d	\nInputs=%d\nnOutputs=%d\nnMULT=%d\nInputsLM=%d\n",STEP,nRealInputs,nOutputs,nSeries_Mtrig,nInputs_LM);
		}
		
		void ReadFromFile(char* f){
			FILE *fin=fopen(f,"r");
			if(fin==nullptr){
				printf("File not found\n");
				return;
			}
			fscanf(fin,"%d %x %d %d %d",&STEP,&VME_ADDR,&nSeries_Mtrig,&nOutputs,&nRealInputs);
			char temp[500];
			fscanf(fin,"%s",temp);
			Default_Save_File=TString(temp);
			fscanf(fin,"%s",temp);
			ACQ_RC_name=TString(temp);
			fscanf(fin,"%s",temp);
			trigbox_name=TString(temp);
			fclose(fin);
			
			if(STEP==1) nFeedback=0;
			else nFeedback=nOutputs;
			
			if(STEP==1) nOutputs_LM=nOutputs+nSeries_Mtrig;
			else nOutputs_LM=nOutputs;
			
			if(STEP==1) nInputs_LM=nRealInputs;
			else nInputs_LM=nRealInputs+nFeedback;
			
			printf("VME_ADDR=%x\n",VME_ADDR);
		}
};*/


//Defines for matching with the firmware, change according to FPGA fw-->Moved to config file
/*#define NSERIES_MTRIG 3
#define NOUTPUTS 8
#define NREALINPUTS 128
#define NFEEDBACK NOUTPUTS

#ifdef STEP_1
	#define NINPUTS  ( NREALINPUTS )
#else
	#define NINPUTS  ( NREALINPUTS + NFEEDBACK )
#endif

#define V1495_ADDR 0xCFF00000*/
// #define LINE() // printf("NOW LINE %d\n", __LINE__);
// 
// 
// 
// //============= CLASSE PER FARE I TEMPI A PASSI DI 25 ns per la V1495 e 20ns per la V2495 =============
// class MyNumberEntry: public TGNumberEntry{
//  public:
//   MyNumberEntry(const TGWindow *parent = 0, Double_t val = 0, int tclk=25,
// 		Int_t digitwidth = 5, Int_t id = -1,
// 		EStyle style = kNESReal,
// 		EAttribute attr = kNEAAnyNumber,
// 		ELimit limits = kNELNoLimits,
// 		Double_t min = 0, Double_t max = 1)
//     : TGNumberEntry(parent,val,digitwidth,id,style,attr,limits,min,max)
//     {LINE();
// 
//     fNumericEntry->SetEnabled(kFALSE);
// 
//     tauclk = tclk;
//     }
// 
//   virtual Bool_t ProcessMessage(Long_t msg, Long_t parm1, Long_t parm2)
//     {LINE();
//     //OKOKOK     printf("PROCESS\n");
//     // Process the up/down button messages. If fButtonToNum is false the
//     // following message is sent: kC_COMMAND, kCM_BUTTON, widget id, param
//     // param % 100 is the step size
//     // param % 10000 / 100 != 0 indicates log step
//     // param / 10000 != 0 indicates button down
// 
//     switch (GET_MSG(msg)) {
//     case kC_COMMAND:
//       {
// 	if ((GET_SUBMSG(msg) == kCM_BUTTON) &&
// 	    (parm1 >= 1) && (parm1 <= 2)) {
// 	  if (fButtonToNum) {
// 	    Int_t sign = (parm1 == 1) ? 1 : -1;
// //	    EStepSize step = (EStepSize) (parm2 % 100);
// //          Bool_t logstep = (parm2 >= 100);
// 
// 	    int val=floor(GetIntNumber()/(double)tauclk)*(double)tauclk;
// 	    if(val<tauclk) val=tauclk;
// 	    if(sign>0)
// 	      SetIntNumber(val+tauclk);
// 	    else
// 	      if(val>tauclk)
// 		SetIntNumber(val-tauclk);
// 
// 	    //               fNumericEntry->IncreaseNumber(step, sign, logstep);
// 	  } else {
// 	    SendMessage(fMsgWindow, msg, fWidgetId,
// 			10000 * (parm1 - 1) + parm2);
// 	    ValueChanged(10000 * (parm1 - 1) + parm2);
// 	  }
// 	  // Emit a signal needed by pad editor
// 	  ValueSet(10000 * (parm1 - 1) + parm2);
// 	}
// 	break;
//       }
//     }
//     return kTRUE;
//     }
// 
//   int tauclk;
// };
// ========================================================

/*
//============= CLASSE PER FARE I TEMPI A PASSI DI 25 ns per la V1495 e 20ns per la V2495 =============
class MyNumberEntry: public TGNumberEntry{
 public:
  MyNumberEntry(const TGWindow *parent = 0, Double_t val = 0, int tclk=25,
		Int_t digitwidth = 5, Int_t id = -1,
		EStyle style = kNESReal,
		EAttribute attr = kNEAAnyNumber,
		ELimit limits = kNELNoLimits,
		Double_t min = 0, Double_t max = 1)
    : TGNumberEntry(parent,val,digitwidth,id,style,attr,limits,min,max)
    {LINE();

    fNumericEntry->SetEnabled(kFALSE);
	
	tauclk =tclk;
    }

  virtual Bool_t ProcessMessage(Long_t msg, Long_t parm1, Long_t parm2)
    {LINE();
    //OKOKOK     printf("PROCESS\n");
    // Process the up/down button messages. If fButtonToNum is false the
    // following message is sent: kC_COMMAND, kCM_BUTTON, widget id, param
    // param % 100 is the step size
    // param % 10000 / 100 != 0 indicates log step
    // param / 10000 != 0 indicates button down

    switch (GET_MSG(msg)) {
    case kC_COMMAND:
      {
	if ((GET_SUBMSG(msg) == kCM_BUTTON) &&
	    (parm1 >= 1) && (parm1 <= 2)) {
	  if (fButtonToNum) {
	    Int_t sign = (parm1 == 1) ? 1 : -1;
//	    EStepSize step = (EStepSize) (parm2 % 100);
//          Bool_t logstep = (parm2 >= 100);

		int val=floor(GetIntNumber()/(double)tauclk)*(double)tauclk;
	    if(val<tauclk) val=tauclk;
	    if(sign>0)
	      SetIntNumber(val+tauclk);
	    else
	      if(val>tauclk)
		SetIntNumber(val-tauclk);

	    //               fNumericEntry->IncreaseNumber(step, sign, logstep);
	  } else {
	    SendMessage(fMsgWindow, msg, fWidgetId,
			10000 * (parm1 - 1) + parm2);
	    ValueChanged(10000 * (parm1 - 1) + parm2);
	  }
	  // Emit a signal needed by pad editor
	  ValueSet(10000 * (parm1 - 1) + parm2);
	}
	break;
      }
    }
    return kTRUE;
    }
    
    int tauclk;
};
// ========================================================
*/

class TriggerBoxGUI_step:public TGMainFrame{
  private:
	TriggerBoxSettings set;
	int ntabs;
	int count_tab1,count_tab2;
 public:
  void Generate_MemoryMapFile();
  bool VerifyMemoryFile();
  void Generate_Output_List();
  void scrivi_val(FILE *f, const char *var, int idx, TGTextButton *b);
  void scrivi_val(FILE *f, const char *var, int idx, TGNumberEntry *b);
  
  // read/write
  void set_default();//
  
  void load_values();
  void write_values();
  
  void read_delays(std::ifstream& input);//
  void write_delays(std::ofstream& output);//
  
  TString GetLMtext(int val);//
  void read_LM(std::ifstream& input);//
  void write_LM(std::ofstream& output);//
  
  void read_general(std::ifstream& input);
  void write_general(std::ofstream& output);
  
  TString GetMasktext(int val);//
  void read_mask(std::ifstream& input);//
  void write_mask(std::ofstream& output);//
  
  TString GetOuttext(int val);//
  void read_out(std::ifstream& input);//
  void write_out(std::ofstream& output);//
  
  void read_reductions(std::ifstream& input);//
  void write_reductions(std::ofstream& output);//
  
  
  
  
  
  
  
  
  
  
  

  TriggerBoxGUI_step(int VME_ADDR,char *file_suff,int link=0,int dev=0);

  void HandleMatrixButton(int code);
  void HandleResetButton();
  void MySetText(TGTextButton *b, TString msg,bool changed=true);

  void HandleOutputButton(int r);

  void HandleMaskButton(int r);

  void force_color(TGFrame *b, const char *col);

  int GetCodeOf(TGTextButton*b);

  void HandleApply();


//   void SendToWebLog(const char *mesg);

  int HandleMenu(int id);
  
  virtual void CloseWindow();
  
  void Changed();
  void Changed_RED_tab1();
  void Changed_RED_tab2();
  
  //copies of buttons for tab2
  TGTextButton ***bottoni_feed_tab2;// [NOUTPUTS]*[NFEEDBACK];
  TGTextButton **bottoni_out_tab2;//[NOUTPUTS];
  TGTextButton **bottoni_mask_tab2;//[NOUTPUTS];
  TGNumberEntry **reductions_tab2;//[NOUTPUTS];
 

 
  TGTextButton ***bottoni;//[NOUTPUTS][NINPUTS];
  
  TGTextButton **bottoni_out;//[NOUTPUTS];
  TGTextButton **bottoni_mask;//[NOUTPUTS];
  TGNumberEntry **reductions;//[NOUTPUTS];
  TGNumberEntry **input_d;//[NREALINPUTS];
  
  TGNumberEntry *input_w;
  TGNumberEntry *resolving;
  TGNumberEntry *output_w;
  TGNumberEntry *output_d;
  
  TString *nomi_input;//[ NINPUTS ];
  TString *nomi_output;//[ NOUTPUTS ];

  TString *nomi_output_fin;//[32];
  TGComboBox *Order_comb;
  TGComboBox *nimttl_comb;
  TGComboBox *nimttlout_comb;
  TGComboBox *Main_comb;
  TGTextButton *applybutton;
  TGMenuBar *bar ;
  
  FVmeTrigBox *TrigBox;
  FVmeControl *vme_control_32;

  TString final_weblog_msg, log_errors;
  TString SAVE_FILE;
  
  int tauclk;
  ClassDef(TriggerBoxGUI_step,1);

};
