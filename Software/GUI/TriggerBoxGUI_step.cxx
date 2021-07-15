#include <TriggerBoxGUI_step.h>
#include "FVmeControl.h"
#include "FVmeTrigBox.h"
#include "infnfi_tbox.h"


// VERSIONE PER WEBLOG 4.0 O SEGUENTI
// per usarla con il vecchio weblog, basta questo define:
// #define OLD_WEBLOG

ClassImp(TriggerBoxGUI_step);

enum{
	MENU_OPENFILE=1,
	MENU_SAVEFILE,
	MENU_EXIT
};

static const char *filetypes[] = { "Trigger setup files", "*.trg",	0 , 0};

void TriggerBoxGUI_step::scrivi_val(FILE *f, const char *var, int idx, TGTextButton *b){
	if(b==NULL) return;
	TString v=b->GetText()->GetString();
	v.ReplaceAll(" ","_");
	//fprintf(f,"%20s %d %s\n",var,idx,v.Data());
	//final_weblog_msg += Form("%s %d %s\n",var,idx,v.Data());
}

void TriggerBoxGUI_step::scrivi_val(FILE *f, const char *var, int idx, TGNumberEntry *b){
	if(b==NULL) return;
	TString v=Form("%d",(int)b->GetIntNumber());
	v.ReplaceAll(" ","_");
	//fprintf(f,"%20s %d %s\n",var,idx,v.Data());
	//final_weblog_msg += Form("%s %d %s\n",var,idx,v.Data());
}



TriggerBoxGUI_step::TriggerBoxGUI_step(int VME_ADDR, char* file_suff, int link,int dev) : TGMainFrame(gClient->GetRoot(),600,600){
	LINE();
	
	//init trigbox
	applybutton=NULL;
	TrigBox=NULL; vme_control_32=NULL;
	if(TrigBox==NULL){
		printf("INIZIALIZZAZIONE TRIGGER BOX...\n");
#ifndef CAEN_VME_BRIDGE
        vme_control_32=new FVmeControl(432);  // window 4  A32 D32
#else
        vme_control_32=new FVmeControl(link,dev);  // window 4  A32 D32
#endif
// #ifdef OLD_DRIVER
// 		vme_control_32=new FVmeControl(32);
// #else
// 		vme_control_32=new FVmeControl(432);  // window 4  A32 D32
// #endif
		TrigBox = new FVmeTrigBox((unsigned int)VME_ADDR,vme_control_32);
		printf("INIZIALIZZAZIONE TRIGGER BOX... DONE\n");
   }// fine init triggerbox
   if(TrigBox->IsV2495()) tauclk = 20;  // V2495 20 ns (50 MHz) FPGA Clock
   else  tauclk = 25;  // V2495 25 ns (50 MHz) FPGA Clock
  TrigBox->SetForcedVeto(1);
   //initialize program with data from triggerbox
   TString sstring="";
   if(file_suff!=NULL) sstring=TString(file_suff);
   printf("%x\n",TrigBox->GetGeneralFWData());
    set.SetData(VME_ADDR,TrigBox->GetGeneralFWData(),sstring);
	if(set.STEP==0){
		printf("Wrong firmware found, use triggerboxgui.out\n");
		exit(-1);		
	}
	SAVE_FILE=set.Default_Save_File;
	
	//    printf("bu\n"); exit(-1);
	
	//check if two tabs are needed
	
	if(set.nRealInputs<=64){
		ntabs=1;
		count_tab1=set.nRealInputs;
		count_tab2=0;
	}
	else{
		ntabs=2;
		int evencount=set.nRealInputs;
		if(evencount%2==1) evencount++;
		count_tab1=count_tab2=evencount/2;
	}
	
	//istanzio gli array necessari di bottoni e stringhe
	bottoni=new TGTextButton**[set.nOutputs_LM];
	for(int i=0;i<set.nOutputs_LM;i++){
		bottoni[i]=new TGTextButton*[set.nInputs_LM];
	}
	
	if(set.STEP==2){
		bottoni_out=new TGTextButton*[set.nOutputs_LM];
		bottoni_mask=new TGTextButton*[set.nOutputs_LM];
		reductions=new TGNumberEntry*[set.nOutputs_LM];
		input_d=new TGNumberEntry*[set.nRealInputs];
	}
	
	nomi_input=new TString[set.nInputs_LM];
	
	nomi_output=new TString[set.nOutputs_LM];	
	
	if(ntabs>1 && set.STEP==2){
		bottoni_feed_tab2=new TGTextButton**[set.nOutputs_LM];;// [NOUTPUTS]*[NFEEDBACK];
		for(int i=0;i<set.nOutputs_LM;i++){
			bottoni_feed_tab2[i]=new TGTextButton*[set.nFeedback];
		}
		bottoni_out_tab2=new TGTextButton*[set.nOutputs_LM];
		bottoni_mask_tab2=new TGTextButton*[set.nOutputs_LM];
		reductions_tab2=new TGNumberEntry*[set.nOutputs_LM];//[NOUTPUTS];		
	}
	
	
	
	//=== lettura nomi:
	//============================= NOTA: questa parte e' presente pari pari in GATriggerBoxGUI.cxx cut&paste :)
	// leggo dal file acq.rc 
	FILE *f=fopen(set.ACQ_RC_name.Data(),"r");
	char temp2[100];
	temp2[0]=0;
	//if(set.STEP==2){
    for(int k=0;k<set.nOutputs;k++){
		LINE();
        if(f) fscanf(f,"%[^\n]\n",temp2);
        else sprintf(temp2,"Out_%d",k);
		//if(k<4) continue;
		nomi_output[k]=temp2;
    }
	
	//generate output names for multiplicity sets
	if(set.STEP==1){
		for(int k=0;k<set.nSeries_Mtrig;k++){
			if(f) fscanf(f,"%[^\n]\n",temp2);
            else sprintf(temp2,"mult_%d",k);
			nomi_output[set.nOutputs+k]=Form("M_%s",temp2);
		}		
	}
	if(f) fclose(f);
	
	
	//Preparo file output if STEP1
	if(set.STEP==1){
		nomi_output_fin=new TString[32];
		for(int k=0;k<set.nOutputs;k++) nomi_output_fin[k]=nomi_output[k];
		for(int j=0;j<set.nSeries_Mtrig;j++){
			for(int k=0;k<8;k++){
				nomi_output_fin[j*8+set.nOutputs+k]=nomi_output[set.nOutputs+j]+Form(">=%d",k+1);
			}
		}
		for(int k=set.nOutputs+8*set.nSeries_Mtrig;k<32;k++) nomi_output_fin[k]="INACTIVE";
	}
		
	
	
	
	// leggo dal file trgboxnames.rc
	f=fopen(set.trigbox_name.Data(),"r");
	if(f==NULL){
		printf("ERROR opening %s\n",set.trigbox_name.Data()); 
        for(int i=0;i<set.nRealInputs;i++){
            sprintf(temp2,"In_%d",i);
            nomi_input[i]=TString(temp2);
        }		
	}
	else{
        temp2[0]=0;
		//real inputs
        TString lll,subfname;
        int k;
        for(k=0;k<set.nRealInputs;){
            LINE();
            if(fscanf(f,"%[^\n]\n",temp2)==0) break;
            lll=temp2;
            while(lll(0)==' ')lll=lll(1,10000);
            if(lll.BeginsWith("<=")){
                printf("Found subfile\n");
                int liminf,usecount;
                liminf=0;
                usecount=32;
                int nfound=0;
                lll=lll(2,1000);
                //printf("CMD line=%s\n",lll.Data());
                TObjArray *tok=lll.Tokenize(TString(" "));
                //for(int ns=0;ns<tok->GetEntries();ns++) printf("%d: %s %d %d\n",ns,(((TObjString*)((*tok)[ns]))->GetString()).Data(),(((TObjString*)((*tok)[ns]))->GetString())[0],' ');
                subfname=((TObjString*)(*tok)[0])->GetString();
                if(tok->GetEntries()>1) usecount=(((TObjString*)((*tok)[1]))->GetString()).Atoi();
                if(tok->GetEntries()>2) liminf=(((TObjString*)(*tok)[2])->GetString()).Atoi();		
                subfname=set.GetOutputName(subfname);
                printf("subf name = --%s--\n",subfname.Data());
                FILE *fsub=fopen(subfname.Data(),"r");
                if(fsub!=0){
                    for(int j=0;j<liminf+usecount && k<set.nRealInputs;j++){
                        if(fscanf(fsub,"%[^\n]\n",temp2)==0) break;
                        if(j<liminf) continue;
                        nfound++;
                        nomi_input[k]=temp2;
                        printf("nomi_input[%d]=%s\n",k,temp2);
                        k++;
                    }
                    fclose(fsub);
                }
                for(;nfound<usecount && k<set.nRealInputs;nfound++){
                    nomi_input[k]="NO NAME!";
                    printf("nomi_input[%d]=NO NAME!\n",k);
                    k++;
                }			
            }
            else if(lll.BeginsWith(">>")){
                int nskip=((TString)lll(2,1000)).Atoi();
                sprintf(temp2,"INACTIVE");
                for(int j=0;j<nskip && k<set.nRealInputs;j++){
                    nomi_input[k]=temp2;
                    printf("nomi_input[%d]=%s\n",k,temp2);
                    k++;
                }			
            }
            else{
                nomi_input[k]=temp2;
                printf("nomi_input[%d]=%s\n",k,temp2);
                k++;
            }
        }
        fclose(f);
        sprintf(temp2,"INACTIVE");
        for(;k<set.nRealInputs;k++){
            nomi_input[k]=temp2;
            printf("nomi_input[%d]=%s\n",k,temp2);
        }
    }
	
	//feedbacks
	if(set.STEP==2){
		for(int k=0;k<set.nFeedback;k++){
			nomi_input[set.nRealInputs+k]=Form("F-%s",nomi_output[k].Data());
			printf("nomi_input[%d]=%s\n",set.nRealInputs+k,nomi_input[set.nRealInputs+k].Data());
		}
	}
	
	bar =new TGMenuBar(this, 100,20);
	TGPopupMenu* generalmenu0 = new TGPopupMenu(gClient->GetRoot());
	
	generalmenu0->AddEntry("Load file from disk...",MENU_OPENFILE);
	generalmenu0->AddEntry("Save configuration to disk...",MENU_SAVEFILE);
	generalmenu0->AddSeparator();
	
	generalmenu0->AddEntry("Exit",MENU_EXIT);
	generalmenu0->Connect("Activated(Int_t)", "TriggerBoxGUI_step", this, "HandleMenu(Int_t)");
	
	bar->AddPopup("&Menu", generalmenu0, new TGLayoutHints(kLHintsLeft | kLHintsTop ,2,2,2,2));
	AddFrame(bar,  new TGLayoutHints(kLHintsLeft | kLHintsTop | kLHintsExpandX,0,0,0,0));
	
	
	
	//    this->SetLayoutManager(new TGMatrixLayout(this,NOUTPUTS+1,NINPUTS+1+3,0,0));
	// #define ATTACCA_FRAME(OBJ) this->AddFrame(OBJ);
	
	TGLabel *titolo=new TGLabel(this,Form("*** TRIGGER BOX CONTROL %s ***", TrigBox->IsV2495()? "V2495":"V1495"));
	this->AddFrame(titolo, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
	
	//To handle many inputs
	
	
	TGTab *mainTabPane=new TGTab(this);
	mainTabPane->AddTab(Form("Inputs %d - %d",0,count_tab1-1));
	if(ntabs>1) mainTabPane->AddTab(Form("Inputs %d - %d",count_tab1,set.nRealInputs-1));
	
	
	
	TGVerticalFrame *tab1Pane=new TGVerticalFrame(mainTabPane->GetTabContainer(0));
	TGVerticalFrame *tab2Pane;
	if(ntabs>1)tab2Pane=new TGVerticalFrame(mainTabPane->GetTabContainer(1));
	
	//Titles for tabs
	TGLabel *titolo_tab1=new TGLabel(tab1Pane,Form("Trigger Inputs %d - %d",0,count_tab1-1));
	tab1Pane->AddFrame(titolo_tab1, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
	TGLabel *titolo_tab2;
	if(ntabs>1){
		titolo_tab2=new TGLabel(tab2Pane,Form("Trigger Inputs %d - %d",count_tab1,set.nRealInputs-1));
		tab2Pane->AddFrame(titolo_tab2, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
	}
	//building matrix(es) of delays
	TGVerticalFrame *matricedelays_1;
	TGVerticalFrame *matricedelays_2;
	
	
	#define NROW_DEL 6
	if(set.STEP==2){
		//tab1
		TGLabel *titolo2_tab1=new TGLabel(tab1Pane,"Delays for input channels:");
		tab1Pane->AddFrame(titolo2_tab1, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		force_color(titolo2_tab1,"yellow");
		int entryperrow=count_tab1;
		if(entryperrow%NROW_DEL !=0) entryperrow=entryperrow+NROW_DEL-entryperrow%NROW_DEL;
		entryperrow/=NROW_DEL;
		
		matricedelays_1=new TGVerticalFrame(tab1Pane);
		matricedelays_1->SetLayoutManager(new TGTableLayout(matricedelays_1,NROW_DEL,entryperrow*2,kFALSE,0));
		
		for(int k=0;k<count_tab1;k++){
			LINE();
			TGLabel *l= new TGLabel(matricedelays_1,Form("  %s",nomi_input[k].Data()));
			l->SetTextJustify(kTextRight);
			input_d[k]=new MyNumberEntry(matricedelays_1,tauclk,tauclk,5,1000+k,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1*tauclk, (1<<16)*tauclk);
			input_d[k]->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed()");
			int row=k/entryperrow;
			int col=k%entryperrow;
			matricedelays_1->AddFrame(l  ,     new  TGTableLayoutHints(2*col,2*col+1,row,row+1, kLHintsFillX ));
			matricedelays_1->AddFrame(input_d[k], new  TGTableLayoutHints(2*col+1,2*col+2,row,row+1, kLHintsFillX));
		}
		
		tab1Pane->AddFrame(matricedelays_1, new TGLayoutHints(kLHintsTop|kLHintsExpandX, 4,4,4,4));
				
		if(ntabs>1){
			//tab2
			TGLabel *titolo2_tab2=new TGLabel(tab2Pane,"Delays for input channels:");
			tab2Pane->AddFrame(titolo2_tab2, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
			force_color(titolo2_tab2,"yellow");
			int entryperrow=count_tab1;
			if(entryperrow%NROW_DEL !=0) entryperrow=entryperrow+NROW_DEL-entryperrow%NROW_DEL;
			entryperrow/=NROW_DEL;
			
			matricedelays_2=new TGVerticalFrame(tab2Pane);
			matricedelays_2->SetLayoutManager(new TGTableLayout(matricedelays_2,NROW_DEL,entryperrow*2,kFALSE,0));
			
			for(int k=0;k<count_tab2;k++){
				LINE();
				TGLabel *l= new TGLabel(matricedelays_2,Form("  %s",nomi_input[k+count_tab1].Data()));
				l->SetTextJustify(kTextRight);
				input_d[k+count_tab1]=new MyNumberEntry(matricedelays_2,tauclk,tauclk,5,1000+k,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1*tauclk, (1<<16)*tauclk);
				input_d[k+count_tab1]->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed()");
				int row=k/entryperrow;
				int col=k%entryperrow;
				matricedelays_2->AddFrame(l  ,     new  TGTableLayoutHints(2*col,2*col+1,row,row+1, kLHintsFillX ));
				matricedelays_2->AddFrame(input_d[k+count_tab1], new  TGTableLayoutHints(2*col+1,2*col+2,row,row+1, kLHintsFillX));
			}
			
			tab2Pane->AddFrame(matricedelays_2, new TGLayoutHints(kLHintsTop|kLHintsExpandX, 4,4,4,4));	
		}		
	}
	
	//Building logic matrix
	//title
	TGLabel *titolo22_tab1=new TGLabel(tab1Pane,Form("Logic Matrix for Inputs %d - %d :",0,count_tab1-1));
	tab1Pane->AddFrame(titolo22_tab1, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
	force_color(titolo22_tab1,"yellow");
	
	if(ntabs>1){
		TGLabel *titolo22_tab2=new TGLabel(tab2Pane,Form("Logic Matrix for Inputs %d - %d :",count_tab1,set.nRealInputs-1));
		tab2Pane->AddFrame(titolo22_tab2, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		force_color(titolo22_tab2,"yellow");
	}
	
	TGVerticalFrame *matrice_1=new TGVerticalFrame(tab1Pane);
	TGVerticalFrame *matrice_2;
	if(ntabs>1) matrice_2=new TGVerticalFrame(tab2Pane);
	
	#define ATTACCA_FRAME(WHERE,OBJ) WHERE->AddFrame(OBJ, new TGTableLayoutHints(c,c+1,r+1,r+1+1, kLHintsFillX | kLHintsFillY));
	const int SIZEX=30;
	const int SIZEY=30;
	


	if(set.STEP==2){
		int RealLM_inputs=count_tab1+set.nFeedback+5;
		matrice_1->SetLayoutManager(new TGTableLayout(matrice_1,set.nOutputs_LM+1,RealLM_inputs,kFALSE,0));  //ROWs : 1 for each trigger + 1 for input names   Columns : 1 for each input(incl feedback) + 1 for output logic  + 1 for output names +1 for red factors + 1 for general trigger mask +1 for trigger label
		if(ntabs>1) matrice_2->SetLayoutManager(new TGTableLayout(matrice_2,set.nOutputs_LM+1,RealLM_inputs,kFALSE,0));
		TGTextButton *b=NULL;
		//matrix of buttons
		int c,r;
		
		//Input and feedback names
		for(int icol=0;icol<set.nInputs_LM;icol++){			
			r=-1;			
			//building name
			LINE();// titoli up:	      
			TString nome=nomi_input[icol];
			TString color="yellow";
			if(icol<set.nRealInputs){
				LINE();
				color="green";
			}
			TString final_t;
			for(unsigned int k=0;k<strlen(nome.Data());k++){
				final_t += nome.Data()[k]+TString("\n");
			}
#if 0
			TGLabel *l= new TGLabel(matrice,final_t);
#else
			gROOT->SetBatch();
			gROOT->SetStyle("Plain");
			static TCanvas *ca= new TCanvas("c","c",22,150);
			ca->Clear();
			if(color=="yellow"){
				LINE();
				ca->SetFillStyle(1001);
				ca->SetFillColor(5);
			}
			TLatex *la=new TLatex(0.9,0.03,final_t);	      
			la->SetNDC();
			la->SetTextAngle(90);
			la->SetTextSize(0.8);
			la->Draw();
			ca->Modified();
			ca->Update();
			TString file=Form("/tmp/trigger_%d.png",icol);
			ca->SaveAs(file,"q");
			gROOT->SetBatch(kFALSE);
			//case 1: icol corresponds to real input
			if(icol<set.nRealInputs){
				if(icol<count_tab1){ //label goes to tab1
					c=icol;
					TGPictureButton *l= new TGPictureButton(matrice_1,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
					force_color(l,color);
					ATTACCA_FRAME(matrice_1,l);		
				}
				else{
					c=icol-count_tab1;
					TGPictureButton *l= new TGPictureButton(matrice_2,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
					force_color(l,color);
					ATTACCA_FRAME(matrice_2,l);						
				}
			}
			else{
				//Both must be placed
				c=icol-set.nRealInputs+count_tab1;
				TGPictureButton *l= new TGPictureButton(matrice_1,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
				force_color(l,color);
				ATTACCA_FRAME(matrice_1,l);	
				if(ntabs>1){
					l= new TGPictureButton(matrice_2,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
					force_color(l,color);
					ATTACCA_FRAME(matrice_2,l);						
				}				
			}
			if(icol==set.nInputs_LM-1){
				ca->Close();
			}
#endif
		}
		
		//LM buttons
		
		for(int icol=0;icol<set.nInputs_LM;icol++){
			LINE();
			//case 1: input button
			if(icol<set.nRealInputs){
				LINE();
				//case 1.1 : first tab
				if(icol<count_tab1){
					c=icol;
					for(r=0;r<set.nOutputs_LM;r++){
						b=new TGTextButton(matrice_1,GUI_X);
						b->Resize(SIZEX,SIZEY);
						b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
						ATTACCA_FRAME(matrice_1,b);
						bottoni[r][icol]=b;
					}					
				}
				//case 1.2 : second tab
				else{
					if(ntabs>1){
						c=icol-count_tab1;
						for(r=0;r<set.nOutputs_LM;r++){
							b=new TGTextButton(matrice_2,GUI_X);
							b->Resize(SIZEX,SIZEY);
							b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
							ATTACCA_FRAME(matrice_2,b);
							bottoni[r][icol]=b;
						}					
					}
				}
			}
			//case 2 : feedback
			else{
				LINE();
				c=icol-set.nRealInputs+count_tab1;
				for(r=0;r<set.nOutputs_LM;r++){
					int fc=icol-set.nRealInputs;
					if(fc==r){//label to avoid self-feedback
						LINE();
						TGLabel *l= new TGLabel(matrice_1,"X");
						bottoni[r][icol]=NULL;
						ATTACCA_FRAME(matrice_1,l);
						if(ntabs>1){
							l=new TGLabel(matrice_2,"X");
							bottoni_feed_tab2[r][fc]=NULL;
							ATTACCA_FRAME(matrice_2,l);						
						}
					}
					else{
						LINE();
						b=new TGTextButton(matrice_1,GUI_X);
						b->Resize(SIZEX,SIZEY);
						b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
						ATTACCA_FRAME(matrice_1,b);
						bottoni[r][icol]=b;		
						if(ntabs>1){
							b=new TGTextButton(matrice_2,GUI_X);
							b->Resize(SIZEX,SIZEY);
							b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
							ATTACCA_FRAME(matrice_2,b);
							bottoni_feed_tab2[r][fc]=b;	
						}
					}
				}
			}			
		}
		
		//Output buttons
		for(r=0;r<set.nOutputs_LM;r++){
			LINE();// trigger +-
			c=count_tab1+set.nFeedback;
			b=new TGTextButton(matrice_1,GUI_X);
			b->Resize(SIZEX,SIZEY);
			b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleOutputButton(=%d)",r));
			ATTACCA_FRAME(matrice_1,b);
			bottoni_out[r]=b;
			MySetText(b, GUI_OR);
			
			if(ntabs>1){
				b=new TGTextButton(matrice_2,GUI_X);
				b->Resize(SIZEX,SIZEY);
				b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleOutputButton(=%d)",r));
				ATTACCA_FRAME(matrice_2,b);
				bottoni_out_tab2[r]=b;
				MySetText(b, GUI_OR);
			}			
		}
		
		//Output names
		//column set.ninputs_lm+1
		for(r=-1;r<set.nOutputs_LM;r++){
			c=count_tab1+1+set.nFeedback;
			if(r<0){
				LINE();
				TGPictureButton *pt= new TGPictureButton(matrice_1,"feedback.png", -1,  TGPictureButton::GetDefaultGC()(), 0);
				ATTACCA_FRAME(matrice_1,pt);
				if(ntabs>1){
					pt= new TGPictureButton(matrice_2,"feedback.png", -1,  TGPictureButton::GetDefaultGC()(), 0);
					ATTACCA_FRAME(matrice_2,pt);
				}
			}
			else{
				LINE();// titoli a sinistra
				TGLabel *l= new TGLabel(matrice_1,nomi_output[r]);
				l->Resize(SIZEX,SIZEY);
				force_color(l,"yellow");
				ATTACCA_FRAME(matrice_1,l);
				if(ntabs>1){
					l= new TGLabel(matrice_2,nomi_output[r]);
					l->Resize(SIZEX,SIZEY);
					force_color(l,"yellow");
					ATTACCA_FRAME(matrice_2,l);
				}
			}
		}
		
		//reductions
		for(r=-1;r<set.nOutputs_LM;r++){
			c=count_tab1+2+set.nFeedback;
			if(r<0){
					LINE();
					ATTACCA_FRAME(matrice_1,new TGLabel(matrice_1,"RED.\n"));
					if(ntabs>1){
						ATTACCA_FRAME(matrice_2,new TGLabel(matrice_2,"RED.\n"));
					}					
			}
			else{
				LINE();
				// reductions
				int val=1;
				TGNumberEntry* n=new TGNumberEntry(matrice_1,val,5,-1,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1, (1<<16));
				n->GetNumberEntry()->SetEnabled(kFALSE);
				n->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed_RED_tab1()");
				reductions[r]=n;
				ATTACCA_FRAME(matrice_1,n);
				if(ntabs>1){
					TGNumberEntry* m=new TGNumberEntry(matrice_2,val,5,-1,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1, (1<<16));
					m->GetNumberEntry()->SetEnabled(kFALSE);
					m->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed_RED_tab2()");
					reductions_tab2[r]=m;
					ATTACCA_FRAME(matrice_2,m);
				}
			}
		}
				
		//Output mask
		for(r=-1;r<set.nOutputs_LM;r++){
			c=count_tab1+3+set.nFeedback;
			if(r<0){
				LINE();
				ATTACCA_FRAME(matrice_1,new TGLabel(matrice_1,"MASK"));
				if(ntabs>1){
					ATTACCA_FRAME(matrice_2,new TGLabel(matrice_2,"MASK"));
				}
			}				
			else{
				LINE();// trigger +-
				b=new TGTextButton(matrice_1,GUI_PASS);
				b->Resize(SIZEX,SIZEY);
				b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMaskButton(=%d)",r));
				ATTACCA_FRAME(matrice_1,b);
				bottoni_mask[r]=b;
				MySetText(b, GUI_PASS);
				if(ntabs>1){
					b=new TGTextButton(matrice_2,GUI_PASS);
					b->Resize(SIZEX,SIZEY);
					b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMaskButton(=%d)",r));
					ATTACCA_FRAME(matrice_2,b);
					bottoni_mask_tab2[r]=b;
					MySetText(b, GUI_PASS);
				}
			}
		}
		//last column: trigger label
		TGLabel *mainl=new TGLabel(matrice_1,"   \n T \n R \n I \n G \n G \n E \n R \n   ");
		force_color(mainl,"yellow");
		matrice_1->AddFrame(mainl, new TGTableLayoutHints(count_tab1+4+set.nFeedback,count_tab1+5+set.nFeedback,1, set.nOutputs_LM+1,kLHintsFillY));	

		if(ntabs>1){
			mainl=new TGLabel(matrice_2,"   \n T \n R \n I \n G \n G \n E \n R \n   ");
			force_color(mainl,"yellow");
			matrice_2->AddFrame(mainl, new TGTableLayoutHints(count_tab1+4+set.nFeedback,count_tab1+5+set.nFeedback,1, set.nOutputs_LM+1,kLHintsFillY));
		}
		
		tab1Pane->AddFrame(matrice_1, new TGLayoutHints(kLHintsTop|kLHintsExpandY|kLHintsExpandX, 4,4,4,4));
		if(ntabs>1) tab2Pane->AddFrame(matrice_2, new TGLayoutHints(kLHintsTop|kLHintsExpandY|kLHintsExpandX, 4,4,4,4));
	}	
	/*****/
	else{
		int RealLM_inputs=count_tab1+2;
		matrice_1->SetLayoutManager(new TGTableLayout(matrice_1,set.nOutputs_LM+1,RealLM_inputs,kFALSE,0));  //ROWs : 1 for each trigger + 1 for input names   Columns : 1 for each input(incl feedback) + 1 for output logic  + 1 for output names +1 for red factors + 1 for general trigger mask +1 for trigger label
		if(ntabs>1) matrice_2->SetLayoutManager(new TGTableLayout(matrice_2,set.nOutputs_LM+1,RealLM_inputs,kFALSE,0));
		TGTextButton *b=NULL;
		//matrix of buttons
		int c,r;
		
		//Input and feedback names
		for(int icol=0;icol<set.nInputs_LM;icol++){			
			r=-1;			
			//building name
			LINE();// titoli up:	      
			TString nome=nomi_input[icol];
			TString color="yellow";
			if(icol<set.nRealInputs){
				LINE();
				color="green";
			}
			TString final_t;
			for(unsigned int k=0;k<strlen(nome.Data());k++){
				final_t += nome.Data()[k]+TString("\n");
			}
#if 0
			TGLabel *l= new TGLabel(matrice,final_t);
#else
			gROOT->SetBatch();
			gROOT->SetStyle("Plain");
			static TCanvas *ca= new TCanvas("c","c",22,150);
			ca->Clear();
			if(color=="yellow"){
				LINE();
				ca->SetFillStyle(1001);
				ca->SetFillColor(5);
			}
			TLatex *la=new TLatex(0.9,0.03,final_t);	      
			la->SetNDC();
			la->SetTextAngle(90);
			la->SetTextSize(1);
			la->Draw();
			ca->Modified();
			ca->Update();
			TString file=Form("/tmp/trigger_%d.png",icol);
			ca->SaveAs(file);
			gROOT->SetBatch(kFALSE);
			//case 1: icol corresponds to real input
			if(icol<set.nRealInputs){
				if(icol<count_tab1){ //label goes to tab1
					c=icol;
					TGPictureButton *l= new TGPictureButton(matrice_1,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
					force_color(l,color);
					ATTACCA_FRAME(matrice_1,l);		
				}
				else{
					c=icol-count_tab1;
					TGPictureButton *l= new TGPictureButton(matrice_2,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
					force_color(l,color);
					ATTACCA_FRAME(matrice_2,l);						
				}
			}
			else{
				//Both must be placed
				c=icol-set.nRealInputs+count_tab1;
				TGPictureButton *l= new TGPictureButton(matrice_1,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
				force_color(l,color);
				ATTACCA_FRAME(matrice_1,l);	
				if(ntabs>1){
					l= new TGPictureButton(matrice_2,file, -1,  TGPictureButton::GetDefaultGC()(), 0);
					force_color(l,color);
					ATTACCA_FRAME(matrice_2,l);						
				}				
			}
			if(icol==set.nInputs_LM-1){
				ca->Close();
			}
#endif
		}
		
		//LM buttons
		
		for(int icol=0;icol<set.nInputs_LM;icol++){
			LINE();
			//case 1: input button
			if(icol<set.nRealInputs){
				LINE();
				//case 1.1 : first tab
				if(icol<count_tab1){
					c=icol;
					for(r=0;r<set.nOutputs_LM;r++){
						b=new TGTextButton(matrice_1,GUI_X);
						b->Resize(SIZEX,SIZEY);
						b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
						ATTACCA_FRAME(matrice_1,b);
						bottoni[r][icol]=b;
					}					
				}
				//case 1.2 : second tab
				else{
					if(ntabs>1){
						c=icol-count_tab1;
						for(r=0;r<set.nOutputs_LM;r++){
							b=new TGTextButton(matrice_2,GUI_X);
							b->Resize(SIZEX,SIZEY);
							b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
							ATTACCA_FRAME(matrice_2,b);
							bottoni[r][icol]=b;
						}					
					}
				}
			}
			//case 2 : feedback
			else{
				LINE();
				c=icol-set.nRealInputs+count_tab1;
				for(r=0;r<set.nOutputs_LM;r++){
					int fc=icol-set.nRealInputs;
					if(fc==r){//label to avoid self-feedback
						LINE();
						TGLabel *l= new TGLabel(matrice_1,"X");
						bottoni[r][icol]=NULL;
						ATTACCA_FRAME(matrice_1,l);
						if(ntabs>1){
							l=new TGLabel(matrice_2,"X");
							bottoni_feed_tab2[r][fc]=NULL;
							ATTACCA_FRAME(matrice_2,l);						
						}
					}
					else{
						LINE();
						b=new TGTextButton(matrice_1,GUI_X);
						b->Resize(SIZEX,SIZEY);
						b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
						ATTACCA_FRAME(matrice_1,b);
						bottoni[r][icol]=b;		
						if(ntabs>1){
							b=new TGTextButton(matrice_2,GUI_X);
							b->Resize(SIZEX,SIZEY);
							b->Connect("Clicked()","TriggerBoxGUI_step",this,Form("HandleMatrixButton(=%d)",r*10000+icol));
							ATTACCA_FRAME(matrice_2,b);
							bottoni_feed_tab2[r][fc]=b;	
						}
					}
				}
			}			
		}
		
		//Output names
		//column set.ninputs_lm+1
		for(r=-1;r<set.nOutputs_LM;r++){
			c=count_tab1;
			if(r>=0){
				LINE();// titoli a sinistra
				TGLabel *l= new TGLabel(matrice_1,nomi_output[r]);
				l->Resize(SIZEX,SIZEY);
				force_color(l,"yellow");
				ATTACCA_FRAME(matrice_1,l);
				if(ntabs>1){
					l= new TGLabel(matrice_2,nomi_output[r]);
					l->Resize(SIZEX,SIZEY);
					force_color(l,"yellow");
					ATTACCA_FRAME(matrice_2,l);
				}
			}
		}
		
	
		//last column: trigger label
		TGLabel *mainl=new TGLabel(matrice_1,"   \n T \n R \n I \n G \n G \n E \n R \n   ");
		force_color(mainl,"yellow");
		matrice_1->AddFrame(mainl, new TGTableLayoutHints(count_tab1+1,count_tab1+2,1, set.nOutputs+1,kLHintsFillY));	
		TGLabel *multl=new TGLabel(matrice_1,"   \n M \n U \n L \n T \n   ");
		force_color(multl,"green");
		matrice_1->AddFrame(multl, new TGTableLayoutHints(count_tab1+1,count_tab1+2,set.nOutputs+1, set.nOutputs_LM+1,kLHintsFillY));

		if(ntabs>1){
			mainl=new TGLabel(matrice_2,"   \n T \n R \n I \n G \n G \n E \n R \n   ");
			force_color(mainl,"yellow");
			matrice_2->AddFrame(mainl, new TGTableLayoutHints(count_tab1+1,count_tab1+2,1, set.nOutputs+1,kLHintsFillY));
			multl=new TGLabel(matrice_2,"   \n M \n U \n L \n T \n   ");
			force_color(multl,"green");
			matrice_2->AddFrame(multl, new TGTableLayoutHints(count_tab1+1,count_tab1+2,set.nOutputs+1, set.nOutputs_LM+1,kLHintsFillY));
		}
		
		tab1Pane->AddFrame(matrice_1, new TGLayoutHints(kLHintsTop|kLHintsExpandY|kLHintsExpandX, 4,4,4,4));
		if(ntabs>1) tab2Pane->AddFrame(matrice_2, new TGLayoutHints(kLHintsTop|kLHintsExpandY|kLHintsExpandX, 4,4,4,4));
	}

	
	mainTabPane->GetTabContainer(0)->AddFrame(tab1Pane,new TGLayoutHints(kLHintsTop|kLHintsExpandY|kLHintsExpandX, 4,4,4,4));
	if(ntabs>1)mainTabPane->GetTabContainer(1)->AddFrame(tab2Pane,new TGLayoutHints(kLHintsTop|kLHintsExpandY|kLHintsExpandX, 4,4,4,4));
	this->AddFrame(mainTabPane,new TGLayoutHints(kLHintsTop|kLHintsExpandX|kLHintsExpandY, 4,4,4,4));	
	
	
	
	
	
	//bottom part
	TGHorizontalFrame *hframe=NULL;
	hframe= new TGHorizontalFrame(this,800,40);
	hframe->AddFrame(new TGLabel(hframe, "Change LEMO input LOGIC type"), new TGLayoutHints(kLHintsCenterY|kLHintsLeft));
	nimttl_comb=new TGComboBox(hframe,-1);
	nimttl_comb->AddEntry("NIM",0);
	nimttl_comb->AddEntry("TTL",1);
	nimttl_comb->Select(0);
	nimttl_comb->Connect("Selected(int)","TriggerBoxGUI_step",this,"Changed()");
	nimttl_comb->SetHeight(20);
  	nimttl_comb->SetWidth(300);
	hframe->AddFrame(nimttl_comb, new TGLayoutHints(kLHintsCenterY|kLHintsLeft, 4,4,4,4));
	AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
    if(set.STEP==2 && TrigBox->IsV2495()){
        hframe= new TGHorizontalFrame(this,800,40);
        hframe->AddFrame(new TGLabel(hframe, "Change LEMO output LOGIC type"), new TGLayoutHints(kLHintsCenterY|kLHintsLeft));
        nimttlout_comb=new TGComboBox(hframe,-1);
        nimttlout_comb->AddEntry("NIM",0);
        nimttlout_comb->AddEntry("TTL",1);
        nimttlout_comb->Select(0);
        nimttlout_comb->Connect("Selected(int)","TriggerBoxGUI_step",this,"Changed()");
        nimttlout_comb->SetHeight(20);
        nimttlout_comb->SetWidth(300);
        hframe->AddFrame(nimttlout_comb, new TGLayoutHints(kLHintsCenterY|kLHintsLeft, 4,4,4,4));
        AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
    }    
	if(set.STEP==1){
		hframe= new TGHorizontalFrame(this,800,40);
		hframe->AddFrame(new TGLabel(hframe, "Change Output ordering"), new TGLayoutHints(kLHintsCenterY|kLHintsLeft));
		Order_comb=new  TGComboBox(hframe,-1);
		Order_comb->AddEntry("A-B-C-D",0xDCBA);
		Order_comb->AddEntry("A-B-D-C",0xCDBA);
		Order_comb->AddEntry("A-C-B-D",0xDBCA);
		Order_comb->AddEntry("A-C-D-B",0xBDCA);
		Order_comb->AddEntry("A-D-B-C",0xCBDA);
		Order_comb->AddEntry("A-D-C-B",0xBCDA);		
		Order_comb->AddEntry("B-A-C-D",0xDCAB);
		Order_comb->AddEntry("B-A-D-C",0xCDAB);
		Order_comb->AddEntry("B-C-A-D",0xDACB);
		Order_comb->AddEntry("B-C-D-A",0xADCB);
		Order_comb->AddEntry("B-D-A-C",0xCADB);
		Order_comb->AddEntry("B-D-C-A",0xACDB);		
		Order_comb->AddEntry("C-A-B-D",0xDBAC);
		Order_comb->AddEntry("C-A-D-B",0xBDAC);
		Order_comb->AddEntry("C-B-A-D",0xDABC);
		Order_comb->AddEntry("C-B-D-A",0xADBC);
		Order_comb->AddEntry("C-D-A-B",0xBADC);
		Order_comb->AddEntry("C-D-B-A",0xABDC);		
		Order_comb->AddEntry("D-A-B-C",0xCBAD);
		Order_comb->AddEntry("D-A-C-B",0xBCAD);
		Order_comb->AddEntry("D-B-A-C",0xCABD);
		Order_comb->AddEntry("D-B-C-A",0xACBD);
		Order_comb->AddEntry("D-C-A-B",0xBACD);
		Order_comb->AddEntry("D-C-B-A",0xABCD);	
		Order_comb->Select(0xDCBA);	
		Order_comb->Connect("Selected(int)","TriggerBoxGUI_step",this,"Changed()");
		Order_comb->SetHeight(20);
  		Order_comb->SetWidth(300);
		hframe->AddFrame(Order_comb, new TGLayoutHints(kLHintsCenterY|kLHintsLeft, 4,4,4,4));
		AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
	}	
	if(set.STEP==2){
		hframe= new TGHorizontalFrame(this,800,40);
		hframe->AddFrame(new TGLabel(hframe, "Change Output trigger connector"), new TGLayoutHints(kLHintsCenterY|kLHintsLeft));
		Main_comb=new TGComboBox(hframe,-1);
		Main_comb->AddEntry("Connector C (LVDS)",0);
		Main_comb->AddEntry("Connector F (ECL or NIM)",1);
		Main_comb->Select(0);
		Main_comb->Connect("Selected(int)","TriggerBoxGUI_step",this,"Changed()");
		Main_comb->SetHeight(20);
  		Main_comb->SetWidth(300);
		hframe->AddFrame(Main_comb, new TGLayoutHints(kLHintsCenterY|kLHintsLeft, 4,4,4,4));
		AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
	}
	
	hframe= new TGHorizontalFrame(this,800,40);
			
		TGLabel *titolo3=new TGLabel(hframe,Form("Input signals width: (ns, %dns resol)",tauclk));
 		hframe->AddFrame(titolo3, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		input_w=new MyNumberEntry(hframe,tauclk,tauclk,5,-1,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1*tauclk, (1<<16)*tauclk);		
		hframe->AddFrame(input_w, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		input_w->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed()");
		AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
		
	if(set.STEP==2){	
		hframe= new TGHorizontalFrame(this,800,40);
		TGLabel *titolo4=new TGLabel(hframe,Form("Main trig resolving time: (ns, %dns resol)",tauclk));
		hframe->AddFrame(titolo4, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		resolving=new MyNumberEntry(hframe,tauclk,tauclk,5,-1,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1*tauclk, (1<<16)*tauclk);		
		hframe->AddFrame(resolving, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		resolving->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed()");
		AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
		
		hframe= new TGHorizontalFrame(this,800,40);
		TGLabel *titolo5=new TGLabel(hframe,Form("Validation  width  and  delay: (ns, %dns resol)",tauclk));
		hframe->AddFrame(titolo5, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		output_w=new MyNumberEntry(hframe,tauclk,tauclk,5,-1,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1*tauclk, (1<<16)*tauclk);
		hframe->AddFrame(output_w, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		output_w->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed()");
		
		output_d=new MyNumberEntry(hframe,tauclk,tauclk,5,-1,TGNumberFormat::kNESInteger,TGNumberFormat::kNEAPositive,TGNumberFormat::kNELLimitMinMax,1*tauclk, (1<<16)*tauclk);
		hframe->AddFrame(output_d, new TGLayoutHints(kLHintsTop|kLHintsFillX, 4,4,4,4));
		output_d->GetNumberEntry()->Connect("TextChanged(const char *)","TriggerBoxGUI_step",this,"Changed()");
	}
	
	TGTextButton *reset_but =new TGTextButton(hframe,"RESET TRIGGER BOX");
	reset_but->Connect("Clicked()","TriggerBoxGUI_step",this,"HandleResetButton()");
        hframe->AddFrame(reset_but, new TGLayoutHints(kLHintsTop|kLHintsRight, 4,4,4,4));
	
	AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
	
	applybutton=new TGTextButton(this,"(up to date)");
	AddFrame(applybutton, new TGLayoutHints(kLHintsTop|kLHintsFillX|kLHintsExpandX, 4,4,4,4));
	applybutton->Connect("Clicked()","TriggerBoxGUI_step",this,"HandleApply()");
	
	Layout();
	SetWindowName("TriggerBoxGUI");
	MapSubwindows();
	// Initialize the layout algorithm
	Resize(GetDefaultSize());
	// Map main frame
	Move(1,1); // upper left corner
	SetWMPosition(1,1);
	
	MapWindow();
	
	printf("GUI is ready, loading setup\n");
	load_values();
	printf("Setup loaded, writing to trigger box\n");
	HandleApply();		
}

void TriggerBoxGUI_step::HandleMatrixButton(int code){
	LINE();
	int c=code%10000;
	int r=(code-c)/10000;
	printf("CHANGING MATRIX BUTTON WITH row=%d col=%d\n",r,c);
	TGTextButton*b=bottoni[r][c];
	if(b==NULL) return;		
	TString old=b->GetText()->GetString();
	TString nuova=" ";
	if(set.STEP==2){
		if(old==GUI_X){
			LINE();
			nuova=GUI_NOT;
		}
		if(old==GUI_NOT){
			LINE();
			nuova=GUI_OR;
		}
		if(old==GUI_OR){
			LINE();
			nuova=GUI_X;
		}
	}
	else{
		if(old==GUI_X){
			LINE();
			nuova=GUI_ACTIVE;
		}
		if(old==GUI_ACTIVE){
			LINE();
			nuova=GUI_X;
		}			
	}
	MySetText(b,nuova);
	if(c>=set.nRealInputs && ntabs>1){
		int fc=c-set.nRealInputs;
		MySetText(bottoni_feed_tab2[r][fc],nuova,false);
	}	
}

void TriggerBoxGUI_step::HandleResetButton(){
	LINE();   
	int retval=kMBYes;
     new TGMsgBox(gClient->GetRoot(), this,"Reset!","Are you sure you want to reset the Trigger Box!?",kMBIconQuestion,kMBYes|kMBNo, &retval);
      if(retval==kMBYes){
           TrigBox->Init();
	}
}

void TriggerBoxGUI_step::MySetText(TGTextButton *b, TString msg,bool changed){
	LINE();
	b->SetText(msg);
	const char *color=NULL;
	if(msg == GUI_OR)  color="green";
	if(msg == GUI_ACTIVE) color="green";
	if(msg == GUI_NOT) color="cyan";
	
	if(msg == GUI_PASS)  color="green";
	if(msg == GUI_VETO) color="red";
	force_color(b,color);
	if(changed) Changed();
}

void TriggerBoxGUI_step::HandleOutputButton(int r){
	if(set.STEP==1) return;
	LINE();
	printf("CHANGING OUTPUT BUTTON WITH row=%d\n",r);
	TGTextButton*b=bottoni_out[r];
	if(b==NULL) return;		
	TString old=b->GetText()->GetString();
	TString nuova=GUI_OR;
	if(old==GUI_OR){
		LINE();
		nuova=GUI_NOT;
	}
	if(old==GUI_NOT){
		LINE();
		nuova=GUI_VETO;
	}
	if(old==GUI_VETO){
		LINE();
		nuova=GUI_OR;
	}
	MySetText(b,nuova);
	if(ntabs>1){
		MySetText(bottoni_out_tab2[r],nuova,false);
	}
}

void TriggerBoxGUI_step::HandleMaskButton(int r){
	if(set.STEP==1) return;
	LINE();
	printf("CHANGING MASK BUTTON WITH row=%d\n",r);
	TGTextButton*b=bottoni_mask[r];
	if(b==NULL) return;		
	TString old=b->GetText()->GetString();
	TString nuova=GUI_PASS;
	if(old==GUI_PASS){
		LINE();
		nuova=GUI_VETO;
	}
	if(old==GUI_VETO){
		LINE();
		nuova=GUI_PASS;
	}
	MySetText(b,nuova);
	if(ntabs>1){
		MySetText(bottoni_mask_tab2[r],nuova,false);
	}
}

void TriggerBoxGUI_step::force_color(TGFrame *b, const char *col){
	LINE();
	if(b==NULL) return;
	Pixel_t mycolor;
	if(col!=NULL){
		LINE();
		gClient->GetColorByName(col, mycolor);
		b->ChangeBackground(mycolor);
	}
	else{
		LINE();
		b->ChangeBackground(b->GetDefaultFrameBackground());
	}
	gClient->NeedRedraw(b);
	gClient->ForceRedraw();  
	//  gSystem->ProcessEvents();
	gClient->HandleInput();		
}

int TriggerBoxGUI_step::GetCodeOf(TGTextButton*b){
	if(b==NULL){
		return 0; // OFF
	}
	TString v=b->GetText()->GetString();
	if(v==GUI_ACTIVE) return 1;
	if(v==GUI_OR) return 1;
	if(v==GUI_NOT) return 2;
	if(v==GUI_PASS) return 1;
	if(v==GUI_X) return 0;
	if(v==GUI_VETO) return 0;		
	printf("ERROR in %s: stringa %s non riconosciuta!\n", __FUNCTION__, v.Data());
	exit(-1);		
}

void TriggerBoxGUI_step::HandleApply(){
	//LINE();
	printf("Inside Handle_APPLY\n");
	/*#ifndef __CINT__
	if(TrigBox==NULL){
		printf("INIZIALIZZAZIONE TRIGGER BOX...\n");
		#ifdef OLD_DRIVER
		vme_control_32=new FVmeControl(32);
		#else
		vme_control_32=new FVmeControl(432);  // window 4  A32 D32
		#endif
		TrigBox = new FVmeTrigBox((unsigned int)set.VME_ADDR,vme_control_32);
		printf("INIZIALIZZAZIONE TRIGGER BOX... DONE\n");
	}// fine init triggerbox*/
	
	
	printf("ORA PROGRAMMO TUTTO.\n");
	//final_weblog_msg="";
	/*FILE *f=fopen(SAVE_FILE.Data(),"w");
	if(f==NULL){
		int retval=-1;
		new TGMsgBox(gClient->GetRoot(), this,"ERROR saving!","ERROR saving/applying data!!!",kMBIconStop,kMBOk, &retval);      
		return;
	}*/
	
	// void scrivi_val(FILE *f, const char *var, int idx, const char *value)
	
	// resetto il resettabile
	TrigBox->Init();
	TrigBox->ResetBitPattern();
	
	//elementi della LM
	//Scrivi su file
	
	for(int o=0;o<set.nOutputs_LM;o++){
		for(int i=0;i<set.nInputs_LM;i++){
			scrivi_val(0,"bottoni",1000*o+i,bottoni[o][i]);
			// logic matrix:
			//   TrigBox->SetLMIn(i,o,GetCodeOf(bottoni[o][i]));
		}
	}


	//Scrivi su TrigBox i bottoni
	int indice=0;
	int count=0;
	int codici[16];
	
	
	if(set.STEP==2){
		if(TrigBox->IsV2495()){
			//printf("Eseguo qui\n");
			for(int i=0;i<16;i++) codici[i]=0;
			for(int o=0;o<set.nOutputs_LM;o++){ //loop over lines
				indice=count=0;
				for(int i=0;i<set.nRealInputs;i++){ //loop over real inputs
					codici[count]=GetCodeOf(bottoni[o][i]);
					count++;
					if(count==8){//finished building vector)
						TrigBox->SetLMIn_128_STEP2(20*o+indice,count,codici);
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					TrigBox->SetLMIn_128_STEP2(20*o+indice,count,codici);
				}
				
				indice=count=0;
				for(int i=set.nRealInputs;i<set.nInputs_LM;i++){ //loop over feed inputs
					codici[count]=GetCodeOf(bottoni[o][i]);
					count++;
					if(count==8){//finished building vector)
						TrigBox->SetLMIn_128_STEP2(20*o+16+indice,count,codici);
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					TrigBox->SetLMIn_128_STEP2(20*o+16+indice,count,codici);
				}
			}			
		}
		else{
			indice=count=0;
			for(int i=0;i<16;i++) codici[i]=0;
			for(int o=0;o<set.nOutputs_LM;o++){
				for(int i=0;i<set.nInputs_LM;i++){
					codici[count]=GetCodeOf(bottoni[o][i]);
					count++;
					if(count==8){//finished building vector)
						TrigBox->SetLMIn_128_STEP2(indice,count,codici);
						count=0;
						indice++;
					}	   
				}
			}
			//write remaining registers
			if(count!=0){
				TrigBox->SetLMIn_128_STEP2(indice,count,codici);
			}
		}
	}
	else{
		if(TrigBox->IsV2495()){
			for(int i=0;i<16;i++) codici[i]=0;
			for(int o=0;o<set.nOutputs;o++){ //loop over lines
				indice=count=0;
				for(int i=0;i<set.nInputs_LM;i++){ //loop over real inputs
					codici[count]=GetCodeOf(bottoni[o][i]);
					count++;
					if(count==16){//finished building vector)
						TrigBox->SetLMIn_128_STEP1(8*o+indice,count,codici);
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					TrigBox->SetLMIn_128_STEP1(8*o+indice,count,codici);
				}				
			}
			
			for(int o=0;o<set.nSeries_Mtrig;o++){ //loop over lines
				indice=count=0;
				for(int i=0;i<set.nInputs_LM;i++){ //loop over real inputs
					codici[count]=GetCodeOf(bottoni[o+set.nOutputs][i]);
					count++;
					if(count==16){//finished building vector)
						TrigBox->SetMultiplicityMask_128_STEP1(8*o+indice,count,codici);
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					TrigBox->SetMultiplicityMask_128_STEP1(8*o+indice,count,codici);
				}				
			}
			
			
		}
		else{
			indice=count=0;
			for(int i=0;i<16;i++) codici[i]=0;
			//logic or masks
			for(int o=0;o<set.nOutputs;o++){
				for(int i=0;i<set.nInputs_LM;i++){
					codici[count]=GetCodeOf(bottoni[o][i]);
					count++;
					if(count==16){//finished building vector)
						TrigBox->SetLMIn_128_STEP1(indice,count,codici);
						count=0;
						indice++;
					}	   
				}
			}
			//write remaining registers
			if(count!=0){
				TrigBox->SetLMIn_128_STEP1(indice,count,codici);
			}
		
			//do the same for multiplicity mask 
			indice=count=0;
			for(int i=0;i<16;i++) codici[i]=0;
			for(int o=0;o<set.nSeries_Mtrig;o++){
				for(int i=0;i<set.nInputs_LM;i++){
					codici[count]=GetCodeOf(bottoni[o+set.nOutputs][i]);
					count++;
					if(count==16){//finished building vector)
						TrigBox->SetMultiplicityMask_128_STEP1(indice,count,codici);
						count=0;
						indice++;
					}	   
				}
			}
			//write remaining registers
			if(count!=0){
				TrigBox->SetMultiplicityMask_128_STEP1(indice,count,codici);
			}
		}
	}
	
	//Maschera degli output e downscaler 
	scrivi_val(0,"input_w",-1,input_w);
	TrigBox->SetInWidth( input_w->GetIntNumber()/tauclk);
		
	if(set.STEP==2){
		for(int o=0;o<set.nOutputs_LM;o++){
			scrivi_val(0,"bottoni_out",o, bottoni_out[o]);
			scrivi_val(0,"bottoni_mask",o, bottoni_mask[o]);
			scrivi_val(0,"reductions",o,  reductions[o]);	
			TrigBox->SetLMOut(o,GetCodeOf(bottoni_out[o]));
			TrigBox->SetTrigMaskBit(o,GetCodeOf(bottoni_mask[o]));
			TrigBox->SetTrigReduction(o,reductions[o]->GetIntNumber());			
		}
		
		//delays
		for(int i=0;i<set.nRealInputs;i+=2){
			int val1,val2;
			scrivi_val(0,"input_d",i,input_d[i]);
			val1=input_d[i]->GetIntNumber()/tauclk;
			val2=0;
			if(i+1<set.nRealInputs){
				scrivi_val(0,"input_d",i+1,  input_d[i+1]);
				val2=input_d[i+1]->GetIntNumber()/tauclk;
			}
			TrigBox->SetInDelay_128_STEP2(i, val1,val2);
		}		
		
		scrivi_val(0,"resolving",-1,resolving);
		TrigBox->SetTrigResTime( resolving->GetIntNumber()/tauclk);
		
		scrivi_val(0,"output_w",-1,output_w);
		TrigBox->SetOutputWidth( output_w->GetIntNumber()/tauclk);
		 
		scrivi_val(0,"output_d",-1,output_d);
		TrigBox->SetOutputDelay( output_d->GetIntNumber()/tauclk);
	}
	
	TrigBox->SetA395DLogic(nimttl_comb->GetSelected());
    if(set.STEP==2 && TrigBox->IsV2495()) TrigBox->SetOutLogic(nimttlout_comb->GetSelected());
	if(set.STEP==1) TrigBox->SetOutputOrder_STEP(Order_comb->GetSelected());
	if(set.STEP==2) TrigBox->SetOutputConnector_STEP(Main_comb->GetSelected());
	//fclose(f);

	Generate_Output_List();
	write_values();
	printf("DATA saved on file %s\n",SAVE_FILE.Data());
	
	TrigBox->ResetScale(); // non servirebbe ma male non fa direi...
	
	applybutton->SetText(Form("OK! (data saved into %s also)",SAVE_FILE.Data()));
	force_color(applybutton,"green");
	force_color(bar,NULL);
	sleep(1);
	applybutton->SetText("(up to date)");
	force_color(applybutton,NULL);
	
	
	for(int k=0;k<set.nInputs_LM;k++){
		TString n=nomi_input[k];
		n.ReplaceAll(" ","_");
		//final_weblog_msg += Form("nomein %d %s\n",k,n.Data());
	}
	
	for(int k=0;k<set.nOutputs_LM;k++){
		TString n=nomi_output[k];
		n.ReplaceAll(" ","_");
		//final_weblog_msg += Form("nomeout %d %s\n",k,n.Data());
	}
	
	//final_weblog_msg="TriggerBoxGUI\n"+final_weblog_msg;
	
	// NOTA: il $_GET finale e' troppo grande... dobbiamo accorciare:
	//       abbrevio tutti i nomi in maniera univoca (spero)
	//final_weblog_msg.ReplaceAll("bottoni","b");
	//final_weblog_msg.ReplaceAll("input","i");
	//final_weblog_msg.ReplaceAll("output","o");
	//final_weblog_msg.ReplaceAll("nome","n");
	//final_weblog_msg.ReplaceAll("resolving","r");
// 	final_weblog_msg.ReplaceAll("reductions","R");
	
	if(TrigBox->IsV2495()){
		//SendToWebLog(final_weblog_msg);		
        printf("Generating Map\n");
		Generate_MemoryMapFile();
        printf("Generated Map\n");
		if(!VerifyMemoryFile()) printf("Warning, something went wrong...\n");
		else printf("Configuration verified\n");
        system("rm TB_memory.map");
	}
//	printf("Exiting\n");
	system("touch /tmp/triggebox_loaded.ok");
//	printf("Exiting\n");
//#endif
}
/*
void TriggerBoxGUI_step::SendToWebLog(const char *mesg){
	#ifndef __CINT__		
	TString log_server="fazia5";
	
	char datadir[20000];
	char temp[20000];
	FILE *f=fopen("acq.rc","r");
	if(f!=NULL){
		fscanf(f,"%s\n", datadir);
		fscanf(f,"%s\n", temp); log_server=temp;
		fclose(f);
	}		
	
	LINE();
	log_errors="ok";
	if(log_server=="none"){
		return;
	}
	
	printf("Sending to %s: %s\n",log_server.Data(), mesg);
	#ifdef NO_VME_CPU
	const  char *ping_cmd="ping %s -W 3 -c 1 >/dev/null"; // pentium
	#else
	const  char *ping_cmd="ping %s -i 3 -c 1 >/dev/null"; // VME
	#endif
	
	if(system(Form(ping_cmd,log_server.Data()))!=0){
		log_errors=Form("ERROR: UNABLE to ping weblog server %s\n   NO LOG WILL BE RECORDED!!!!\n",log_server.Data());			
		printf("%s\n",log_errors.Data()); return;
	}
	
	int sockfd, portno, n;
	struct sockaddr_in serv_addr;
	struct hostent *server;
	char buffer[20000];
	portno = 80;
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	if (sockfd < 0){
		log_errors=Form("ERROR opening socket to web log\n");
		printf("%s\n",log_errors.Data()); return;
	}
	server = gethostbyname(log_server.Data());
	if (server == NULL){
		log_errors=Form("ERROR: %s: no such host\n", log_server.Data());
		printf("%s\n",log_errors.Data()); return;
	}
	bzero((char *) &serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	bcopy((char *)server->h_addr,
		  (char *)&serv_addr.sin_addr.s_addr,
		  server->h_length);
	serv_addr.sin_port = htons(portno);
	if (connect(sockfd,(const sockaddr*)&serv_addr,sizeof(serv_addr)) < 0){
		log_errors=Form("ERROR connecting to %s for web_log\n", log_server.Data());
		printf("%s\n",log_errors.Data()); return;
	}
	
	TString m=mesg;
	m.ReplaceAll(" ","+");
	m.ReplaceAll("\n","<br>");
	m.ReplaceAll("&","AND");
	m.ReplaceAll("?",". ");
	
	#ifndef OLD_WEBLOG
	sprintf(buffer,"GET /weblog/index.php?pID=add_entry&tipo=ACQ&message=%s HTTP/1.0\r\n\r\n",m.Data());
	#else
	sprintf(buffer,"GET /web_log/add_entry.php?tipo=ACQ&message=%s\n\n",m.Data());
	#endif
	n = write(sockfd,buffer,strlen(buffer));
	if (n < 0){
		log_errors=Form("ERROR in web_log: writing to socket\n");
	}
	bzero(buffer,256);
	n = read(sockfd,buffer,255);
	close(sockfd);
	
	if (n < 0){
		log_errors=Form("ERROR in web_log: reading from socket\n");
		printf("%s\n",log_errors.Data()); return;
	}
	TString b=buffer;
	if(!b.Contains("OK")){
		LINE();
		log_errors=Form("ERROR: writing to web_log: no OK answer");
		printf("weblog ANSWERED: \"%s\"\n",buffer);
		LINE();
	}
	LINE();
	
	#endif  
}*/

int TriggerBoxGUI_step::HandleMenu(int id){
	printf("NOW HandleMenu with id %d\n", id);
	if(id==MENU_EXIT) exit(0);		
	if(id==MENU_SAVEFILE){
		static TString dir(".");
		TGFileInfo fi;
		fi.fFileTypes = filetypes;
		fi.fIniDir    = StrDup(dir.Data());
		new TGFileDialog(gClient->GetRoot(),this,kFDSave, &fi);
		if(fi.fFilename==NULL) return 0;
		SAVE_FILE=fi.fFilename;
		if(strncmp(SAVE_FILE.Data()+strlen(SAVE_FILE.Data())-4,".trg",4)!=0){
			SAVE_FILE += ".trg";
		}
		HandleApply();
		SAVE_FILE=set.Default_Save_File;
		return 0;
	}
	if(id==MENU_OPENFILE){
		static TString dir(".");
		TGFileInfo fi;
		fi.fFileTypes = filetypes;
		fi.fIniDir    = StrDup(dir.Data());
		new TGFileDialog(gClient->GetRoot(),this,kFDOpen, &fi);
		if(fi.fFilename==NULL) return 0;
		SAVE_FILE=fi.fFilename;
		load_values();
		SAVE_FILE=set.Default_Save_File;
		HandleApply();
		return 0;
	}
	return -1;
}

void TriggerBoxGUI_step::CloseWindow(){
	printf("\n\n*** BYE BYE ***\n\n");
	exit(-1);
}

void TriggerBoxGUI_step::Changed(){
	LINE();
	if(applybutton==NULL) return;
	//    printf("CHANGED!!!!!!!!\n");
	applybutton->SetText("DATA CHANGED: click to APPLY");
	force_color(applybutton,"red");
	force_color(bar,"red");
}

void TriggerBoxGUI_step::Changed_RED_tab1(){
	LINE();
	//printf("Tab=%d\n",tab);
	if(set.STEP==2 && ntabs>1){
		for(int i=0;i<set.nOutputs_LM;i++){
			reductions_tab2[i]->SetIntNumber(reductions[i]->GetIntNumber());
		}
	}
	Changed();
}

void TriggerBoxGUI_step::Changed_RED_tab2(){
	LINE();
	//printf("Tab=%d\n",tab);
	if(set.STEP==2 && ntabs>1){
		for(int i=0;i<set.nOutputs_LM;i++){
			reductions[i]->SetIntNumber(reductions_tab2[i]->GetIntNumber());
		}
	}
	Changed();
}

void TriggerBoxGUI_step::Generate_MemoryMapFile(){
	system("rm TB_memory.map");
	FILE *fmap=fopen("TB_memory.map","w");
	fprintf(fmap,"%d %d\n%d %d\n",0x1080,0x9BF,0x1084,TrigBox->GetGeneralFWData());
	printf("Scritto header\n");
	//Delays (only STEP2)
	int basea=INFNFI2_TBOX_GDGEN_DEL;
	if(set.STEP==2){
		for(int i=0;i<64 && 2*i<set.nRealInputs;i++){
			int temp=0;
			int val1,val2;
			val1=input_d[2*i]->GetIntNumber()/tauclk;
			val2=0;
			if(2*i+1<set.nRealInputs){
				val2=input_d[2*i+1]->GetIntNumber()/tauclk;
			}
			temp=(val2<<8) | val1;
			fprintf(fmap,"%d %d\n",basea,temp);
			basea+=4;
		}		
	}
	printf("Scritto GD_GEN\n");
	
	//Gate width
	fprintf(fmap,"%d %ld\n",INFNFI2_TBOX_GDGEN_WID,input_w->GetIntNumber()/tauclk);
	
	//Logic matrix
	int indice=0;
	int count=0;
	int temp;
	int codici[16];
	
	if(set.STEP==2){
			for(int i=0;i<16;i++) codici[i]=0;
			for(int o=0;o<set.nOutputs_LM;o++){ //loop over lines
				basea=INFNFI2_TBOX_LMINPUT+20*4*o;
				temp=0;
				indice=count=0;
				for(int i=0;i<set.nRealInputs;i++){ //loop over real inputs
					codici[count]=GetCodeOf(bottoni[o][i]);
					temp=temp| (GetCodeOf(bottoni[o][i])<<(2*count));
					count++;
					if(count==8){//finished building vector)
						fprintf(fmap,"%d %d\n",basea+indice*4,temp);
						temp=0;
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					fprintf(fmap,"%d %d\n",basea+indice*4,temp);
				}
				
				indice=count=0;
				temp=0;
				for(int i=set.nRealInputs;i<set.nInputs_LM;i++){ //loop over feed inputs
					codici[count]=GetCodeOf(bottoni[o][i]);
					temp=temp| (GetCodeOf(bottoni[o][i])<<(2*count));
					count++;
					if(count==8){//finished building vector)
						fprintf(fmap,"%d %d\n",basea+indice*4+64,temp);
						temp=0;
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					fprintf(fmap,"%d %d\n",basea+indice*4+64,temp);						
				}
			}			
		}
	else{
			for(int i=0;i<16;i++) codici[i]=0;
			for(int o=0;o<set.nOutputs;o++){ //loop over lines
				basea=INFNFI2_TBOX_LMINPUT+8*4*o;
				indice=count=0;
				temp=0;
				for(int i=0;i<set.nInputs_LM;i++){ //loop over real inputs
					codici[count]=GetCodeOf(bottoni[o][i]);
					temp=temp| (GetCodeOf(bottoni[o][i])<<(count));					
					count++;
					if(count==16){//finished building vector)
						fprintf(fmap,"%d %d\n",basea+indice*4,temp);
						temp=0;
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					fprintf(fmap,"%d %d\n",basea+indice*4,temp);						
				}				
			}
			
			for(int o=0;o<set.nSeries_Mtrig;o++){ //loop over lines
				basea=INFNFI_TBOX_LM_MULTINPUT+8*4*o;
				temp=0;
				indice=count=0;
				for(int i=0;i<set.nInputs_LM;i++){ //loop over real inputs
					codici[count]=GetCodeOf(bottoni[o+set.nOutputs][i]);
					temp=temp| (GetCodeOf(bottoni[o+set.nOutputs][i])<<(count));					
					count++;
					if(count==16){//finished building vector)
						fprintf(fmap,"%d %d\n",basea+indice*4,temp);
						temp=0;
						count=0;
						indice++;
						for(int j=0;j<16;j++) codici[j]=0;
					}	
				}
				if(count!=0){
					fprintf(fmap,"%d %d\n",basea+indice*4,temp);
				}				
			}			
	}	
	printf("Scritto LM\n");
	if(set.STEP==2){
		//Output 
		for(int i=0;i<set.nOutputs_LM;i++){
			fprintf(fmap,"%d %d\n",INFNFI2_TBOX_LMOUTPUT+4*i,GetCodeOf(bottoni_out[i]));	
		}
		//bottoni_mask
		int temp=0;
		for(int i=0;i<set.nOutputs_LM;i++){
			temp=temp|(GetCodeOf(bottoni_mask[i])<<i);
		}
		fprintf(fmap,"%d %d\n",INFNFI2_TBOX_RED_MASK,temp);
		
		//reductions
		for(int i=0;i<set.nOutputs_LM;i++){
			fprintf(fmap,"%d %ld\n",INFNFI2_TBOX_REDUCTION+4*i,reductions[i]->GetIntNumber());	
		}
		fprintf(fmap,"%d %ld\n",INFNFI2_TBOX_TRIG_REST,resolving->GetIntNumber()/tauclk);
		fprintf(fmap,"%d %ld\n",INFNFI2_TBOX_MAINTR_WID,output_w->GetIntNumber()/tauclk);	
		fprintf(fmap,"%d %ld\n",INFNFI2_TBOX_MAINTR_DEL,output_d->GetIntNumber()/tauclk);	
	}
	printf("Scritto LM_OUT\n");
	fclose(fmap);	
    printf("chiuso file\n");
}

bool TriggerBoxGUI_step::VerifyMemoryFile(){
	FILE *f=fopen("TB_memory.map","r");
	if(f==NULL){
		printf("ERROR opening memory file");
		return false;
	}
	bool result=true;
	while(1){
		int Address;
		unsigned short CC;
		if(fscanf(f,"%d %hu\n",&Address,&CC)<=0) break;
		unsigned short temp=TrigBox->ReadRegister(Address);
		if(temp!=CC){
			printf("Mismatch at address %x\n",Address);
			result=false;
		}		
	}
	fclose(f);
	return result;
}

void TriggerBoxGUI_step::set_default(){
	if(set.STEP==2){
		//delays
		for(int i=0;i<set.nRealInputs;i++) input_d[i]->SetIntNumber(tauclk);
		//reductions
		for(int i=0;i<set.nOutputs_LM;i++) reductions[i]->SetIntNumber(1);
		//bottoni out
		for(int i=0;i<set.nOutputs_LM;i++) MySetText(bottoni_out[i],GetOuttext(1));
		//bottoni mask
		for(int i=0;i<set.nOutputs_LM;i++) MySetText(bottoni_mask[i],GetMasktext(1));
		output_w->SetIntNumber(tauclk);
		output_d->SetIntNumber(tauclk);
		resolving->SetIntNumber(tauclk);
	}	
	nimttl_comb->Select(0);
    if(set.STEP==2 && TrigBox->IsV2495()) nimttlout_comb->Select(0);
	if(set.STEP==1) Order_comb->Select(0xDCBA);
	//LM
	for(int i=0;i<set.nOutputs_LM;i++){
		for(int j=0;j<set.nInputs_LM;j++){
			if(bottoni[i][j]!=nullptr) MySetText(bottoni[i][j],GetLMtext(0));
		}
	}
	input_w->SetIntNumber(tauclk);		
}
  
  void TriggerBoxGUI_step::load_values(){
	  std::ifstream inf;
	  inf.open(SAVE_FILE.Data());
	  if(!inf.is_open()){
		  printf("File not found, aborting!\n");
		  return;
	  }
	  int checkr;
	  inf>>checkr;
	  if(checkr!=TrigBox->GetGeneralFWData()){
		  printf("File not compatible, aborting!\n");
		  return;
	  }
	  std::string temps;
	  TString Ttemps;
	  while(getline(inf,temps)){
		Ttemps=TString(temps.c_str());
		if(Ttemps=="#IN_DELAYS"){
			read_delays(inf);
		}
		else if(Ttemps=="#LMBUTTONS"){
			read_LM(inf);
		}
		else if(Ttemps=="#MASK_BTN"){
			read_mask(inf);
		}
		else if(Ttemps=="#OUT_BTN"){
			read_out(inf);
		}
		else if(Ttemps=="#REDUCTIONS"){
			read_reductions(inf);
		}
		else if(Ttemps=="#GENERAL"){
			read_general(inf);
		}
		else continue;		  
	  }
	  inf.close();
	  if(ntabs>1 && set.STEP==2){
			//printf("Updating second tab data\n");
			// update also second tab
			for(int r=0;r<set.nOutputs_LM;r++){
				MySetText(bottoni_mask_tab2[r],bottoni_mask[r]->GetText()->GetString(),false);
				MySetText(bottoni_out_tab2[r],bottoni_out[r]->GetText()->GetString(),false);
				reductions_tab2[r]->SetIntNumber(reductions[r]->GetIntNumber());
				for(int fc=0;fc<set.nFeedback;fc++){
					if(fc!=r) MySetText(bottoni_feed_tab2[r][fc],bottoni[r][fc+set.nRealInputs]->GetText()->GetString(),false);
				}
			}
		}
  }
  
  void TriggerBoxGUI_step::write_values(){
	  std::ofstream outf;
	  outf.open(SAVE_FILE.Data());
	  outf<<TrigBox->GetGeneralFWData()<<"\n";
	  write_delays(outf);
	  write_LM(outf);
	  write_general(outf);
	  write_mask(outf);
	  write_out(outf);
	  write_reductions(outf);
	  outf.close();
  }
  
  
  void TriggerBoxGUI_step::read_delays(std::ifstream& input){
		TString temp;
		std::string temps;
		int idX,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps.c_str());
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>idX>>bV;
			if(idX<set.nRealInputs){
			 	int iv=(int)(round((double)bV/tauclk))*tauclk;				
				input_d[idX]->SetIntNumber(iv);
			}
			else printf("Found value of non existing input delay %d\n",idX);
		}	  	  
  }
  
  void TriggerBoxGUI_step::write_delays(std::ofstream& output){
		if(set.STEP!=2) return;
		output<<"#IN_DELAYS\n";
		for(int i=0;i<set.nRealInputs;i++){
			output<<i<<" "<<input_d[i]->GetIntNumber()<<"\n";
		}
		output<<"#END\n";	  
  }
  
  TString TriggerBoxGUI_step::GetLMtext(int val){
	  if(val==0){
		return TString(GUI_X);		  
	  }
	  if(val==1){
		if(set.STEP==2) return TString(GUI_OR);
		else return TString(GUI_ACTIVE);
	  }
	  if(val==2){
		if(set.STEP==2) return TString(GUI_NOT);
		else return TString(GUI_X);
	  }
	  return TString(GUI_X);	  
  }
  
  void TriggerBoxGUI_step::read_LM(std::ifstream& input){
		TString temp;
		std::string temps;
		int bX,bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps.c_str());
			if(temp=="#END") break;
			std::istringstream iss(temps);
			iss>>bY>>bX>>bV;
			if(bottoni[bY][bX]!=nullptr) MySetText(bottoni[bY][bX],GetLMtext(bV));
			else printf("Found status of non existing LM button\n");
		}	  
  }
  
  void TriggerBoxGUI_step::write_LM(std::ofstream& output){
		output<<"#LMBUTTONS\n";
		for(int i=0;i<set.nOutputs_LM;i++){
			for(int j=0;j<set.nInputs_LM;j++){
				if(bottoni[i][j]!=nullptr) output<<i<<" "<<j<<" "<<GetCodeOf(bottoni[i][j])<<"\n";
			}
		}
		output<<"#END\n";
  }
  
  void TriggerBoxGUI_step::read_general(std::ifstream& input){
	  TString temp;
	  std::string temps;
	  int idX,bV;
	  while(true){
			getline(input,temps);
			temp=TString(temps.c_str());
			if(temp=="#END") break;
			std::istringstream iss(temps);
			iss>>idX>>bV;
			if(idX>7) continue;
			else if(idX==0){
				int iv=(int)(round((double)bV/tauclk))*tauclk;				
				input_w->SetIntNumber(iv);				
			}
			else if(idX==4){
				nimttl_comb->Select(bV);				
			}
			else if(idX==5 && set.STEP==1){
				//printf("Selecting ordering %x (%d)\n",bV,bV);
				Order_comb->Select(bV);
			}			
			else if(idX>0 && set.STEP==2){
				int iv=(int)(round((double)bV/tauclk))*tauclk;				
				if(idX==1) output_w->SetIntNumber(iv);
				if(idX==2) output_d->SetIntNumber(iv);
				if(idX==3) resolving->SetIntNumber(iv);
				if(idX==6) Main_comb->Select(bV);
                if(idX==7 && TrigBox->IsV2495()) nimttlout_comb->Select(bV);
			}
			else printf("Found value of non existing general info\n");
		}	 	  
  }
  
  void TriggerBoxGUI_step::write_general(std::ofstream& output){
		output<<"#GENERAL\n";
		output<<"0 "<<input_w->GetIntNumber()<<"\n";
		if(set.STEP==2){
			output<<"1 "<<output_w->GetIntNumber()<<"\n";
			output<<"2 "<<output_d->GetIntNumber()<<"\n";
			output<<"3 "<<resolving->GetIntNumber()<<"\n";
		}
		output<<"4 "<<nimttl_comb->GetSelected()<<"\n";
		if(set.STEP==1){
			output<<"5 "<<Order_comb->GetSelected()<<"\n";
		}
		if(set.STEP==2){
			output<<"6 "<<Main_comb->GetSelected()<<"\n";
			if(TrigBox->IsV2495()) output<<"7 "<<nimttlout_comb->GetSelected()<<"\n";
		}
		output<<"#END\n";	  
  }
  
  TString TriggerBoxGUI_step::GetMasktext(int val){
		if(val==1) return TString(GUI_PASS);
		return TString(GUI_VETO);
  }
  
  void TriggerBoxGUI_step::read_mask(std::ifstream& input){
		TString temp;
		std::string temps;
		int bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps.c_str());
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>bY>>bV;
			if(bY<set.nOutputs_LM) MySetText(bottoni_mask[bY],GetMasktext(bV));
			else printf("Found status of non existing MASK button\n");
		}	 	  
  }
  
  void TriggerBoxGUI_step::write_mask(std::ofstream& output){
		if(set.STEP!=2) return;
		output<<"#MASK_BTN\n";
		for(int i=0;i<set.nOutputs_LM;i++){
			output<<i<<" "<<GetCodeOf(bottoni_mask[i])<<"\n";
		}
		output<<"#END\n";	  
  }
  
  TString TriggerBoxGUI_step::GetOuttext(int val){
	  if(val==2) return TString(GUI_NOT);
	  if(val==1) return TString(GUI_OR);
	  return TString(GUI_VETO);
  }
  
  void TriggerBoxGUI_step::read_out(std::ifstream& input){
		TString temp;
		std::string temps;
		int bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps.c_str());
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>bY>>bV;
			if(bY<set.nOutputs_LM) MySetText(bottoni_out[bY],GetOuttext(bV));
			else printf("Found status of non existing OUT button\n");
		}	 	  
  }
  
  void TriggerBoxGUI_step::write_out(std::ofstream& output){
		if(set.STEP!=2) return;
		output<<"#OUT_BTN\n";
		for(int i=0;i<set.nOutputs_LM;i++){
			output<<i<<" "<<GetCodeOf(bottoni_out[i])<<"\n";
		}
		output<<"#END\n";	  
  }
  
  void TriggerBoxGUI_step::read_reductions(std::ifstream& input){
		TString temp;
		std::string temps;
		int bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps.c_str());
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>bY>>bV;
			if(bY<set.nOutputs_LM) reductions[bY]->SetIntNumber(bV);
			else printf("Found status of non existing OUT button\n");
		}	 	  
  }
  
  void TriggerBoxGUI_step::write_reductions(std::ofstream& output){
		if(set.STEP!=2) return;
		output<<"#REDUCTIONS\n";
		for(int i=0;i<set.nOutputs_LM;i++){
			output<<i<<" "<<reductions[i]->GetIntNumber()<<"\n";
		}
		output<<"#END\n";	  
  }
  
  
  void TriggerBoxGUI_step::Generate_Output_List(){
		FILE *f;
	  	if(set.STEP==1){
			f=fopen(set.output_gen.Data(),"w");
			int ioff;
			int iord;
			int ordreg=Order_comb->GetSelected();
			for(int ott=0;ott<4;ott++){
				iord=(ordreg>>(4*ott)) & 0xF;
				if(iord>13 || iord<10){
					for(int i=0;i<8;i++) fprintf(f,"UNUSED\n");
				}
				else{
					ioff=8*(iord-10);
					for(int i=0;i<8;i++) fprintf(f,"%s\n",nomi_output_fin[ioff+i].Data());
				}
			}
			fclose(f);
		}
	}
	
