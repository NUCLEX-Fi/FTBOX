
#include <GATriggerBoxLA_step.h>
#include "FVmeControl.h"
#include "FVmeTrigBox.h"

ClassImp(GATriggerBoxLA_step);
void force_color(TGFrame *b, const char *col)
{LINE();
 if(b==NULL) return;
 Pixel_t mycolor;
    
 if(col!=NULL)
   {LINE();
   gClient->GetColorByName(col, mycolor);
   b->ChangeBackground(mycolor);
   }
 else
   {LINE();
   b->ChangeBackground(b->GetDefaultFrameBackground());
   }
 gClient->NeedRedraw(b);
 gClient->ForceRedraw();  
 //  gSystem->ProcessEvents();
 gClient->HandleInput();
   
}

void GATriggerBoxLA_step::TrigBoardModel(){ 
    if(tbox->is_V2495==1){
      is_V2495=1;
      tauclk = 20; // 20ns clock
    }
    else{
      is_V2495=0;
      tauclk = 25; // 25ns clock
    }
    printf("v2495=%d tauclk=%d\n",is_V2495,tauclk);
  }
  

  int GATriggerBoxLA_step::TrigBoardData(){
	  return (int)(tbox->ReadReg(INFNFI_BOARD_DATA));
//       *(unsigned short *)(la+INFNFI_BOARD_FWDATA));
  }


  int GATriggerBoxLA_step::TrigBoardOrder(){
	  return (int)(tbox->ReadReg(INFNFI_TBOX_ORD));
//       *(unsigned short *)(la+INFNFI_TBOX_ORD));
  }


GATriggerBoxLA_step::GATriggerBoxLA_step(int VMEADDR,char* suff,int link,int dev,unsigned short pretrig,unsigned short leng,unsigned int tb_mask,unsigned short tb_mux, int tb_nsignals,int tb_ext_trigger):TGMainFrame(gClient->GetRoot(),600,600){
//	mux_subselector=0;
#ifndef CAEN_VME_BRIDGE
        vme=new FVmeControl(432);  // window 4  A32 D32
#else
        vme=new FVmeControl(link,dev);  // window 4  A32 D32
#endif
  tbox = new FVmeTrigBox((unsigned int)VMEADDR,vme);
  //la=(unsigned char *)vme->VmeMapMem(0x9000,VMEADDR); 
  TrigBoardModel();
  /*if(is_V2495==0){
  	printf("Logic analyzer feature not yet implemented for V1495 boards\n");
	exit(-1);  
  }*/
  TString strsuff="";
  if(suff!=NULL) strsuff=TString(suff);
  set.SetData(VMEADDR,TrigBoardData(),strsuff);
  if(set.STEP==0){
	printf("Found older firmware, use old Logic Analyzer program\n");
	exit(-1);	  
  }
  
  current_event=0;
  //=== lettura nomi:
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
  
	
	
	//Preparo Lista
	if(set.STEP==1){
		for(int k=0;k<set.nOutputs;k++) nomi_output_fin[k]=nomi_output[k];
		for(int j=0;j<set.nSeries_Mtrig;j++){
			for(int k=0;k<8;k++){
				nomi_output_fin[j*8+set.nOutputs+k]=nomi_output[set.nOutputs+j]+Form(">=%d",k+1);
			}
		}
		for(int k=set.nOutputs+8*set.nSeries_Mtrig;k<32;k++) nomi_output_fin[k]="INACTIVE";
	}
	
	//riordino la lista
	if(set.STEP==1){
			int ioff;
			int iord;
			int ordreg=TrigBoardOrder();
			for(int ott=0;ott<4;ott++){
				iord=(ordreg>>(4*ott)) & 0xF;
				if(iord>13 || iord<10){
					for(int i=0;i<8;i++) nomi_output_ord[8*ott+i]="UNUSED";
				}
				else{
					ioff=8*(iord-10);
					for(int i=0;i<8;i++) nomi_output_ord[8*ott+i]=nomi_output_fin[ioff+i];
				}
			}
		}
	else{
		for(int i=0;i<32;i++) nomi_output_ord[i]=nomi_output[i];		
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
	

  gROOT->SetStyle("Plain");
  gStyle->SetOptDate(1);

  ecanv= new TRootEmbeddedCanvas("Ecanvas",this,1000,800);

  AddFrame(ecanv, new TGLayoutHints(kLHintsExpandX| kLHintsExpandY,
				    3,3,3,1));

  TGHorizontalFrame *hframe=NULL;


  hframe= new TGHorizontalFrame(this,800,40);
  hframe->AddFrame(new TGLabel(hframe, "Change visible channels (MUX)"), new TGLayoutHints(kLHintsNormal));
  combo_mux= new TGComboBox(hframe,-1);
  TString triade="+ResTime(29)+TRG0(30)+veto(31)";
  int nsub=(int)ceil((double)set.nRealInputs/32.);
  for(int i=0;i<nsub;i++){
		combo_mux->AddEntry(Form("SUBTRG: Input subtriggers %d-%d",32*i,32*(i+1)-1),0x1+(i<<11)); 	  
  }
  if(set.STEP==2){
	  for(int i=0;i<nsub;i++){
		combo_mux->AddEntry(Form("SUBTRG: GateDelayGen Output %d-%d",32*i,32*(i+1)-1),0x2+(i<<11)); 	  
	  }
	  combo_mux->AddEntry("TRG: Logic Mat Output"+triade,0x3);
	  combo_mux->AddEntry("TRG: Triggers Post VETO"+triade,0x4);
	  combo_mux->AddEntry("TRG: Triggers Post Red"+triade,0x5);
	  combo_mux->AddEntry("TRG: Bit Pattern"+triade,0x6);
	  combo_mux->AddEntry("MIX: GDG OUT(0-15) + LM Out (0-7)"+triade,0x7);
	  combo_mux->AddEntry("MIX: GDG OUT(16-31) + LM Out (0-7)"+triade,0x8);
	  combo_mux->AddEntry("MIX: GDG OUT(0-15) + Reduction (0-7)"+triade,0x9);
	  combo_mux->AddEntry("MIX: GDG OUT(16-31) + Reduction (0-7)"+triade,0xA);
	  combo_mux->AddEntry("11: unused",0xB);
	  combo_mux->AddEntry("12: unused",0xC);
	  combo_mux->AddEntry("13: unused",0xD);
	  combo_mux->AddEntry("14: unused",0xE);
  }
  else{
  	for(int i=0;i<nsub;i++){
		combo_mux->AddEntry(Form("SUBTRG: GateGen Output %d-%d",32*i,32*(i+1)-1),0x2+(i<<11)); 	  
	}
  	combo_mux->AddEntry("TRG: Logic Mat Output",0x3);
  }
  combo_mux->AddEntry("DEBUG: Set all to 1",0xF);

  combo_mux->SetHeight(25);
  combo_mux->SetWidth(400);
  if(set.STEP==2)  combo_mux->Select(0x7);  
  else combo_mux->Select(0x3);  

  hframe->AddFrame(combo_mux, new TGLayoutHints(kLHintsNormal));

  AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));

  hframe= new TGHorizontalFrame(this,800,40);
  hframe->AddFrame(new TGLabel(hframe, "Pretrigger (ns) "), new TGLayoutHints(kLHintsNormal));
  pretrigger=new MyNumberEntry(hframe,pretrig*tauclk,tauclk,5,-1,  TGNumberFormat::kNESInteger,
			       TGNumberFormat::kNEAPositive,
			       TGNumberFormat::kNELLimitMinMax,
			       1*tauclk, (1<<16)*tauclk);
  
  hframe->AddFrame(pretrigger, new TGLayoutHints(kLHintsNormal));
  AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));


  hframe= new TGHorizontalFrame(this,800,40);
  hframe->AddFrame(new TGLabel(hframe, "Signals Len (ns) "), new TGLayoutHints(kLHintsNormal));
  viewlen=new MyNumberEntry(hframe,leng*tauclk,tauclk,5,-1,  TGNumberFormat::kNESInteger,
			    TGNumberFormat::kNEAPositive,
			    TGNumberFormat::kNELLimitMinMax,
			    1*tauclk, (1<<16)*tauclk);
  hframe->AddFrame(viewlen, new TGLayoutHints(kLHintsNormal));
  AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));


  pretrigger->GetNumberEntry()->Connect("TextChanged(const char *)","GATriggerBoxLA_step",this,"Changed()");
  viewlen    ->GetNumberEntry()->Connect("TextChanged(const char *)","GATriggerBoxLA_step",this,"Changed()");
  combo_mux->Connect("Selected(int)","GATriggerBoxLA_step",this,"Changed()");


  hframe= new TGHorizontalFrame(this,800,40);
  hframe->AddFrame(new TGLabel(hframe, "Trigger source:"), new TGLayoutHints(kLHintsNormal));

  triggeron_main=new TGCheckButton(hframe,"<-MAIN  ");
  triggeron_main->SetState(kButtonDown);  
  triggeron_main->Connect("Clicked()","GATriggerBoxLA_step",this,"Changed()"); 

  hframe->AddFrame(triggeron_main, new TGLayoutHints(kLHintsNormal));

  for(int k=0;k<32;k++)
    {
	triggeron_input[k]=new TGCheckButton(hframe,(k%8-7)==0?Form("<-%d",k):"");
      	triggeron_input[k]->Connect("Clicked()","GATriggerBoxLA_step",this,"Changed()");
      	hframe->AddFrame(triggeron_input[k], new TGLayoutHints(kLHintsNormal));
      
    }

  AddFrame(hframe, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));
 


  button_enable=new TGTextButton(this,"       Status: enabled         ");
  force_color(button_enable,"green");
  button_enable->Connect("Clicked()","GATriggerBoxLA_step",this,"RearmChanged()");
  AddFrame(button_enable, new TGLayoutHints(kLHintsLeft|kLHintsExpandX,2,2,2,2));

  

  this->pretrig=pretrig;
  this->len=leng; 
  this->mask=tb_mask;
  this->mux=tb_mux;
  this->nsignals=tb_nsignals;
  this->ext_trigger=tb_ext_trigger;
  this->pt= new TLine();
  for(int pers=0; pers<NPERSISTENZA; pers++){
    for(int jbit=0; jbit<nsignals; jbit++){
      sigs[pers][jbit] = new TH1F(Form("sig%d-%d",jbit,pers),Form("S%d",jbit),len,0.,tauclk*len);
      sigs[pers][jbit] ->GetXaxis()->SetTitle("Time (ns)");
      sigs[pers][jbit] ->GetXaxis()->SetNdivisions(520);
    }
  }
  gPad->SetTicks(1,1);
  gPad->SetGridx();

  set_mux(mux);
  set_mask(mask);
  printf("%x\n",la);
  unsigned short ptr[10];
  get_la(ptr);
  set_la(pretrig,len);
  printf("mask=%8.8x\n",get_mask());
  get_la(ptr);


  Changed(); // <<<<<<<<<<<<<<<<<<<< qui sincronizzo grafica e hardware <<<<

  Layout();
  SetWindowName("GATriggerBoxLA_step");
  MapSubwindows();
  // Initialize the layout algorithm
  Resize(GetDefaultSize());
  // Map main frame
  Move(1,1); // upper left corner
  SetWMPosition(1,1);
    
  MapWindow();
  ecanv->GetCanvas()->cd();
  gPad->SetLeftMargin(0.02);
  gPad->SetRightMargin(0.001);
  TTimer* update_timer= new TTimer(100);
  update_timer->Connect("Timeout()",  "GATriggerBoxLA_step",this, "MyTimer()");
  update_timer->TurnOn();
}

void GATriggerBoxLA_step::ExtractSignals()
{
  unsigned int tog;

  int BASEADDR=TBOX_LA;
  int step=tbox->bytes_per_reg;
//   unsigned char *la_out=(la+TBOX_LA);

  if(current_event>200)
    {
       button_enable->SetTitle("Status: enabled");
       RearmChanged(); 
       current_event=0;
       return;
    } ; // ammazzo il programma se qualcuno l'ha dimenticato aperto :)

  const int ce=current_event % NPERSISTENZA;
  //printf("current event is %d, riempio l'histo %d\n", current_event,ce);

  // ridimensiono (solo se serve)
  static int last_len=-1;;
  if(last_len!=len)
    {
      // printf("HISTO RESIZE!\n");
      last_len=len;
      for(int kce=0;kce<NPERSISTENZA;kce++)
	for(int jbit=0; jbit<nsignals;jbit++)
	  sigs[kce][jbit]->SetBins(len,0,tauclk*len);
    }
  int nstep=1;
  //unsigned int *dati32;
  //unsigned short *dati16;
  //if(is_V2495)
	//dati32=(unsigned int *)la_out;
  //else
   // {
//	dati16=(unsigned short *)la_out;
 //       nstep=2;
   // }
  if(!is_V2495) nstep=2;
        
  for(int isample=0,n=0; isample<len;isample++, n+=nstep)
    {
      if(is_V2495)
	{
         tog=tbox->ReadRegInt(BASEADDR+n*step);
         tog=tbox->ReadRegInt(BASEADDR+n*step);
        }
      else
        {
         tog=tbox->ReadReg(BASEADDR+n*step)<<16;   
         tog=tbox->ReadReg(BASEADDR+n*step)<<16;
         tog|=tbox->ReadReg(BASEADDR+(n+1)*step);
         tog|=tbox->ReadReg(BASEADDR+(n+1)*step);
//          tog=dati16[n]<<16;
//          tog=dati16[n]<<16;
//          tog|=dati16[n+1]; 
//          tog|=dati16[n+1];
        } 
     // if(is_V2495)printf("addressRead=%8.8x isample=%d  %8.8x\n",&dati32[n],isample,tog); 
      //else printf("addressRead=%8.8x isample=%d  %8.8x\n",&dati16[n],isample,tog); 

      for(int jbit=0; jbit<nsignals;jbit++)
       {
	 if(tog & (1<<jbit))
	   {
	     //	sigs[jbit]->SetData(isample,100.);
	     sigs[ce][jbit]->SetBinContent(isample+1,100.);
	   }else{
	     //	sigs[jbit]->SetData(isample,0.);
	     sigs[ce][jbit]->SetBinContent(isample+1,0.);
	   }
// #warning per debug
// 	 sigs[ce][jbit]->SetBinContent(isample+1,0.);
// 	 sigs[ce][jbit]->SetBinContent(100+10*current_event+jbit/4., 100); // contatore d'evento :))

       }
     }

  return;
}
void GATriggerBoxLA_step::rearm_and_wait()
{
//   *(la+TBOX_LA)=1;
  tbox->WriteReg(TBOX_LA,1);
  trigger_status.SetTitle("WAITING FOR TRIGGER...");
#define TIMEOUT_TRIGGER 10
  int counter=0;
  if(is_V2495)
    {
     //printf("sono qui 2495\n");
     while(tbox->ReadReg(CURRENT_POINTER2)<tbox->ReadReg( LAST_POINTER2)){
       // printf("Curr ptr = %d\n",*((unsigned short *)(la+CURRENT_POINTER2)));
      if(counter > TIMEOUT_TRIGGER) return;
      usleep(1000);
      counter++;
      }
    }
  else
    {
    // printf("sono qui 1495\n");
     
     while(tbox->ReadReg(CURRENT_POINTER)<tbox->ReadReg( LAST_POINTER)){
       //printf("Curr ptr = %d\n",*((unsigned short *)(la+CURRENT_POINTER)));
      if(counter > TIMEOUT_TRIGGER) return;
      usleep(1000);
      counter++;
      }
    }
    
  //printf("TRIGGERED\n");
  current_event++;
  trigger_status.SetTitle(Form("TRIGGERED (ev %d)", current_event));

}

void GATriggerBoxLA_step::rearm()
{
  tbox->WriteReg(TBOX_LA,1);

}
void GATriggerBoxLA_step::sw_trigger()
{
  if(is_V2495)
    tbox->WriteReg(TBOX_LA+4,1);  
    //*(la+TBOX_LA+4)=1;
  else
    tbox->WriteReg(TBOX_LA+2,1);    
//     *(la+TBOX_LA+2)=1;

}


void GATriggerBoxLA_step::wait_trig()
{
  if(is_V2495)
   {
    while(tbox->ReadReg(CURRENT_POINTER2)<tbox->ReadReg( LAST_POINTER2))
                  gSystem->Sleep(100);
   }
  else
   {
    while(tbox->ReadReg(CURRENT_POINTER)<tbox->ReadReg( LAST_POINTER))
                  gSystem->Sleep(100);
   }

}

int GATriggerBoxLA_step::data_ready()
{
  if(is_V2495)
    {
     if(tbox->ReadReg(CURRENT_POINTER2)<tbox->ReadReg( LAST_POINTER2)) return 0;
     else
       return 1;
    }
  else
    {
     if(tbox->ReadReg(CURRENT_POINTER)<tbox->ReadReg( LAST_POINTER)) return 0;
     else
       return 1;
    }


}

void GATriggerBoxLA_step::SetPreTrigger(int ptrg)
{
  pretrig=ptrg;
  tbox->WriteReg(PRE_TRIGGER,ptrg-1);
//   *((unsigned short *)(la+PRE_TRIGGER))=(unsigned short)(ptrg-1);
}

void GATriggerBoxLA_step::SetLength(int length)
{
  len = length;
  if(is_V2495)
    tbox->WriteReg(LAST_POINTER2,length);
//     *((unsigned short *)(la+LAST_POINTER2))=(unsigned short)length;
  else
    tbox->WriteReg(LAST_POINTER,length);
//     *((unsigned short *)(la+LAST_POINTER))=(unsigned short)length;

}

void GATriggerBoxLA_step::set_la(unsigned int ptrg, unsigned int length)
{
  SetPreTrigger(ptrg);
  SetLength(length);
  return;
}

void GATriggerBoxLA_step::set_mask(unsigned int mask)
{
  if(is_V2495)
    {
    tbox->WriteReg(MASK_HIGH2,((mask&0xFFFF0000)>>16));
    tbox->WriteReg(MASK_LOW2,(mask&0xFFFF));
//         *((unsigned short *)(la+MASK_HIGH2))=(unsigned short)((mask&0xFFFF0000)>>16);
//      *((unsigned short *)(la+MASK_LOW2))=(unsigned short)((mask&0xFFFF));
     gSystem->Sleep(1); 
     /* printf("set mask hi word: %4.4x     low word: %4.4x\n",
        *((unsigned short *)(la+MASK_HIGH2)),
        *((unsigned short *)(la+MASK_LOW2))); */
     return;
    }
  else
    {
    tbox->WriteReg(MASK_HIGH,((mask&0xFFFF0000)>>16));
    tbox->WriteReg(MASK_LOW,(mask&0xFFFF));
//      *((unsigned short *)(la+MASK_HIGH))=(unsigned short)((mask&0xFFFF0000)>>16);
//      *((unsigned short *)(la+MASK_LOW))=(unsigned short)((mask&0xFFFF));
     gSystem->Sleep(1); 
     /* printf("set mask hi word: %4.4x     low word: %4.4x\n",
	 *((unsigned short *)(la+MASK_HIGH)),
         *((unsigned short *)(la+MASK_LOW))); */
     return;
    }

}

unsigned int GATriggerBoxLA_step::get_mask()
{
  unsigned int mask=0;
  if(is_V2495)
    {
     mask=tbox->ReadReg(MASK_HIGH2)<<16;
     mask|=tbox->ReadReg(MASK_LOW2);
    }
  else
    {
    mask=tbox->ReadReg(MASK_HIGH)<<16;
    mask|=tbox->ReadReg(MASK_LOW);
    }

  return mask;
}

void GATriggerBoxLA_step::get_la(unsigned short *ptr)
{
  if(is_V2495)
    {
     for(int j=0 ; j <4 ; j++)
      {
       ptr[j]=tbox->ReadReg(PRE_TRIGGER+j*4);
       //*((unsigned short *)(la+PRE_TRIGGER+j*4));
       printf("j=%d  %4.4x\n",j,ptr[j]);
      }
    }
  else
    {
      for(int j=0 ; j <4 ; j++)
      {
       ptr[j]=tbox->ReadReg(PRE_TRIGGER+j*2);
//        ptr[j]=*((unsigned short *)(la+PRE_TRIGGER+j*2));
       printf("j=%d  %4.4x\n",j,ptr[j]);
      }
    }

}

void GATriggerBoxLA_step::set_mux(unsigned short val)
{
  unsigned short vreg=tbox->ReadReg(INFNFI_TBOX_CTRL) & (~0x180F);
  vreg!=(val&0x180F);
  tbox->WriteReg(INFNFI_TBOX_CTRL,vreg);
//   *((unsigned short *)(la+INFNFI_TBOX_CTRL))&=(~0x180F);
//   *((unsigned short *)(la+INFNFI_TBOX_CTRL))|=(val&0x180F);
  // printf("mux=%4.4x\n",*((unsigned short *)(la+INFNFI_TBOX_CTRL)));
}

void GATriggerBoxLA_step::Draw()
{
  //  system("clear");
  ExtractSignals();
  //     *(sigs[0]) += nsignals*200.;
  //sigs[0]->Draw("nocanvas");

  for(int nb=1; nb<=sigs[0][0]->GetNbinsX();nb++)
    sigs[0][0]->SetBinContent(nb,
			   sigs[0][0]->GetBinContent(nb)+nsignals*200.);
  sigs[0][0]->SetStats(kFALSE);
  sigs[0][0]->Draw();

  //      ((TH1F *)gROOT->FindObjectAny("FSignal"))->GetYaxis()->SetRangeUser(0.,nsignals*200+400);
  //      ((TH1F *)gROOT->FindObjectAny("FSignal"))->SetFillStyle(1001);
  //      ((TH1F *)gROOT->FindObjectAny("FSignal"))->SetFillColor(18);
  //      ((TH1F *)gROOT->FindObjectAny("FSignal"))->SetTitle("Trigger Box Logic Analyzer");


  sigs[0][0]->GetYaxis()->SetRangeUser(0.,nsignals*200+400);


//   sigs[0][0]->SetFillStyle(1001);
//   sigs[0][0]->SetFillColor(18);




  sigs[0][0]->SetTitle("Trigger Box Logic Analyzer");

  //  printf("Setto i colori: ce idx=%d\n", current_event%NPERSISTENZA);
  // setto i colori, tenendo conto della persistenza:
  // in questo loop pers==0 e' il piu' intenso
  for(int pers=0;pers<NPERSISTENZA;pers++)
    {
      int ce=(current_event+pers)%NPERSISTENZA;

      for(int jbit=0; jbit<nsignals;jbit++)
	{
// #warning per debug
// 	  sigs[ce][jbit]->SetLineColor(jbit+1); continue;

	  if(pers==0)
	    sigs[ce][jbit]->SetLineWidth(2);
	  else
	    sigs[ce][jbit]->SetLineWidth(1);

	  if((jbit%2+1)==2) // ROSSO
	    {
	      sigs[ce][jbit]->SetLineColor(jbit%2+1);
  	      if(pers==0)  continue;
//     	      if(pers>0 && pers<=3)
//     		sigs[ce][jbit]->SetLineColor(kRed-1-3*pers);
//     	      else
  		sigs[ce][jbit]->SetLineColor(kRed -9);
	    }
	  else
	    {//NERO
	      sigs[ce][jbit]->SetLineColor(jbit%2+1);
  	      if(pers==0)  continue;
//   	      if(pers>0 && pers<=4)
//   		sigs[ce][jbit]->SetLineColor(kGray+3+1-pers);
//   	      else
 		sigs[ce][jbit]->SetLineColor(kGray);
	    }
	}
    }

  //  printf("============ CURRENT EVENT = %d ====================\n",current_event);
  for(int kpers=0;kpers<NPERSISTENZA;kpers++)
    {
      // quello di current event lo faccio per ultimo... vado a gambero...
      int pers=(current_event+1+kpers)%NPERSISTENZA;
      // printf("Drawing pers=%d\n", pers);
      for(int jbit=0; jbit<nsignals;jbit++)
	{
	  if(!(jbit==0 && pers==0)) //il [0][0] e' gia' fatto
	    if( kpers==NPERSISTENZA-1) // devo spostare solo l'evento corrente
	    for(int nb=1; nb<=sigs[0][0]->GetNbinsX();nb++)
	      sigs[pers][jbit]->SetBinContent(nb,
					      sigs[pers][jbit]->GetBinContent(nb)+(nsignals-jbit)*200.);

	  // #warning "tolto per debug"
	  if(nomi_assey[jbit].GetTitle()!=TString(""))
	    sigs[pers][jbit]->Draw("same");
	  
	}
    }
  pt->SetX1(pretrig*tauclk);
  pt->SetX2(pretrig*tauclk);
  pt->SetY1(0.);
  pt->SetY2(nsignals*200+400);
  pt->SetLineColor(2);
  pt->SetLineStyle(2);
  pt->SetLineWidth(2);
  pt->Draw("same");

  for(int k=0;k<nsignals;k++)
    {
      nomi_assey[k].SetY(200*(nsignals-k)+10);
      nomi_assey[k].SetX(100);
      nomi_assey[k].SetTextColor(k%2+1);
      nomi_assey[k].SetTextSize( 0.02);
      nomi_assey[k].Draw();
    }
  trigger_status.SetX(0.6);
  trigger_status.SetY(0.91);
  trigger_status.SetNDC();
  trigger_status.Draw();

  Changed(); // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
}

void GATriggerBoxLA_step::MyTimer()
{
  TString t=button_enable->GetTitle();
  if(!t.Contains("enabled")) return;

  //printf("MYTIMER!!!\n");

  TCanvas *c1=ecanv->GetCanvas();
  //  SetExternalTrigger(1);
  
  Draw();
  c1->Modified();
  c1->Update();
  rearm_and_wait();  
}

void GATriggerBoxLA_step::SetExternalTrigger(int ext_trigger){
  // if 0 reset   if 1 set 
  if(ext_trigger)   {
     unsigned short vreg=tbox->ReadReg(INFNFI_TBOX_CTRL)|(1<<5);
     tbox->WriteReg(INFNFI_TBOX_CTRL,vreg);
//       *((unsigned short *)(la+INFNFI_TBOX_CTRL))|=(1<<5);
      //     printf("INFN_TBOX_CTRL=%4.4x\n",*((unsigned short *)(la+INFNFI_TBOX_CTRL)));
    }else
      {
        unsigned short vreg=tbox->ReadReg(INFNFI_TBOX_CTRL)&(~(1<<5));
     tbox->WriteReg(INFNFI_TBOX_CTRL,vreg);
// 	*((unsigned short *)(la+INFNFI_TBOX_CTRL))&=(~(1<<5));
      }


}

void GATriggerBoxLA_step::Changed()
{
  unsigned int mask;

  //printf("CHANGED!!!\n");

  set_mux(combo_mux->GetSelected());
  static int last_mux=combo_mux->GetSelected();
  if(last_mux != combo_mux->GetSelected() )
    {// reset persistenza
      last_mux=combo_mux->GetSelected();
      for(int k=0;k<NPERSISTENZA;k++)
	for(int jbit=0;jbit<32;jbit++)
	  sigs[k][jbit]->Reset();
    }

  SetPreTrigger(pretrigger->GetIntNumber()/tauclk);
  SetLength(viewlen->GetIntNumber()/tauclk);

  // gestione trigger del LA:
  int wants_triggeron_main=triggeron_main->GetState()==kButtonDown ? kTRUE  : kFALSE;
  mask = 0;
  for(int nbit=0; nbit<32;nbit++)
    if(triggeron_input[nbit]->GetState()==kTRUE) mask |= (1<<nbit);

  if(set.STEP==1 && wants_triggeron_main) mask=0xFFFFFFFF;
  set_mask(mask);

  if(wants_triggeron_main) SetExternalTrigger(1);
  else  SetExternalTrigger(0);

  // a seconda del valore di MUX devo aggiustare i nomi: i valori
  // "pretty" di in e out sono nei vettori nomi_input e nomi_output

  // dummy:
  for(int nbit=0; nbit<32;nbit++)
    nomi_assey[nbit].SetTitle("");

  int mainselector=combo_mux->GetSelected() & 0x7FF;
  int subselector=((combo_mux->GetSelected())>>11) & 0x1F;

  switch(mainselector){
  case 1:
        for(int k=0;k<nsignals;k++) nomi_assey[k].SetTitle(nomi_input[k+32*subselector]);
    break;
  case 2:
        for(int k=0;k<nsignals;k++) nomi_assey[k].SetTitle(nomi_input[k+32*subselector]);
    break;
  case 3:
  case 4:
  case 5:
  case 6:
        for(int k=0;k<8;k++) nomi_assey[k].SetTitle(nomi_output_ord[k]);
        if(set.STEP==2){
		nomi_assey[29].SetTitle("Res.Time");
	        nomi_assey[30].SetTitle("TRG0");
        	nomi_assey[31].SetTitle( "Veto");
	}
	else{
	   for(int k=8;k<32;k++){
			nomi_assey[k].SetTitle(nomi_output_ord[k]);
		}
	}
	
    	break;
  case 7:
  case 9:
        for(int k=0;k<16;k++) nomi_assey[k].SetTitle(nomi_input[k]);
        for(int k=16;k<24;k++) nomi_assey[k].SetTitle(nomi_output_ord[k-16]);
	nomi_assey[29].SetTitle("Res.Time");
        nomi_assey[30].SetTitle("TRG0");
        nomi_assey[31].SetTitle( "Veto");
    break;
  case 8:
  case 10:
        for(int k=16;k<32;k++) nomi_assey[k].SetTitle(nomi_input[k]);
        for(int k=16;k<24;k++) nomi_assey[k].SetTitle(nomi_output_ord[k-16]);
	nomi_assey[29].SetTitle("Res.Time");
        nomi_assey[30].SetTitle("TRG0");
        nomi_assey[31].SetTitle( "Veto");
    break;
  case 15:
        for(int k=0;k<32;k++) nomi_assey[k].SetTitle("Set to High");
    break;
  default:
        for(int k=0;k<nsignals;k++) nomi_assey[k].SetTitle("??");
  
  }



}

void GATriggerBoxLA_step::RearmChanged()
{
  TString t=button_enable->GetTitle();
  if(t.Contains("enabled"))
    {
      button_enable->SetTitle("Status: stopped (click to re-enable)");
      force_color(button_enable,"red");
      trigger_status.SetTitle("[STOPPED]");
      trigger_status.SetTextColor(2);
    }
  else
    {
      button_enable->SetTitle("Status: enabled");
      force_color(button_enable,"green");
      trigger_status.SetTextColor(1);
    }
  
  TCanvas *c1=ecanv->GetCanvas();
  c1->Modified();
  c1->Update();
}


/*
  debug_mux:PROCESS(RST,CLK,ctrl_register)
  BEGIN
  debug_signal <= (others =>'0');
  if(ctrl_register(3 downto 0) = X"1") then
  debug_signal <= SUBTRG_INPUT_32(NBIT_DEBUG-1 downto 0);
  elsif(ctrl_register(3 downto 0) = X"2") then
  debug_signal <= from_resolving_time(NBIT_DEBUG-1 downto 0);
  elsif(ctrl_register(3 downto 0) = X"3") then
  debug_signal(NBIT_TRIG-1 downto 0) <= from_logic_matrix;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"4") then
  debug_signal(NBIT_TRIG-1 downto 0) <= from_busy;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"5") then
  debug_signal(NBIT_TRIG-1 downto 0) <= from_downscaler;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"6") then
  debug_signal <= from_trg_and_pat;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"7") then
  debug_signal <= bit_pattern ;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"8") then
  debug_signal(15 downto 0) <= from_resolving_time(15 downto 0) ;
  debug_signal(23 downto 16) <= from_logic_matrix(7 downto 0) ;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"9") then
  debug_signal(15 downto 0) <= from_resolving_time(31 downto 16) ;
  debug_signal(23 downto 16) <= from_logic_matrix(7 downto 0) ;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"A") then
  debug_signal(15 downto 0) <= from_resolving_time(15 downto 0) ;
  debug_signal(23 downto 16) <= from_downscaler(7 downto 0) ;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"B") then
  debug_signal(15 downto 0) <= from_resolving_time(31 downto 16) ;
  debug_signal(23 downto 16) <= from_downscaler(7 downto 0) ;
  debug_signal(NBIT_DEBUG-1) <= VETO_SIGNAL;
  debug_signal(NBIT_DEBUG-2) <= from_trg_and_pat(0);
  elsif(ctrl_register(3 downto 0) = X"F") then
  debug_signal <= (others =>'1');
  end if;
  END PROCESS debug_mux;

*/

