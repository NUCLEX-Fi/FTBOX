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

#include <TApplication.h>
#include <TGFrame.h>
#include <TGTableLayout.h>
#include <TGButton.h>
#include <TGLabel.h>
#include <TGTab.h>
#include <TGNumberEntry.h>
#include <TROOT.h>
#include <TGMenu.h>
#include <TCanvas.h>
#include <TLatex.h>

#include <TGFileDialog.h>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <fstream>
#include <sstream>

#include <TGMsgBox.h>
#include "GlobalClasses.h"
#include "infnfi_tbox.h"
class FVmeControl;
class FVmeTrigBox;

class Programma_TBOX_STEP{
  private:
	TriggerBoxSettings set;
	bool isCP;
 public:	
  bool isReady(){
	return isCP;
 }

  void Generate_MemoryMapFile();
  bool VerifyMemoryFile();
  // read/write
  void load_values();
  
  void read_delays(std::ifstream& input);//
  
  void read_LM(std::ifstream& input);//
  
  void read_general(std::ifstream& input);
  
  void read_mask(std::ifstream& input);//
  
  void read_out(std::ifstream& input);//
  
  void read_reductions(std::ifstream& input);//

void Generate_Output_List();
 
  Programma_TBOX_STEP(int VME_ADDR,char *file_suff,int link=0,int dev=0);

  bool HandleApply();

  int **bottoni;//[NOUTPUTS][NINPUTS];
  
  int *bottoni_out;//[NOUTPUTS];
  int *bottoni_mask;//[NOUTPUTS];
  int *reductions;//[NOUTPUTS];
  int *input_d;//[NREALINPUTS];
  
  int input_w;
  int resolving;
  int output_w;
  int output_d;
  
  int nimttl_comb;
  int nimttlout_comb;
  int Order_comb;
  int Main_comb;
  
  FVmeTrigBox *TrigBox;
  FVmeControl *vme_control_32;
  TString SAVE_FILE;
  int tauclk;

  TString nomi_output[32];
  TString nomi_output_fin[32];
};
