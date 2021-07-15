#include "Programma_TBOX_STEP.h"
#include "FVmeControl.h"
#include "FVmeTrigBox.h"
#include "infnfi_tbox.h"


Programma_TBOX_STEP::Programma_TBOX_STEP(int VME_ADDR, char* file_suff,int link,int dev){
	LINE();
	
	//init trigbox
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
// 	FILE *f=fopen(set.ACQ_RC_name.Data(),"r");
// 	char temp2[100];
// 	temp2[0]=0;
// 	for(int k=0;k<set.nOutputs+3;k++){
// 		LINE();
// 		fscanf(f,"%[^\n]\n",temp2);
// 		if(k<3) continue;
// 		nomi_output[k-3]=temp2;
// 	}
// 	
// 	//generate output names for multiplicity sets
// 	if(set.STEP==1){
// 		for(int k=0;k<set.nSeries_Mtrig;k++){
// 			fscanf(f,"%[^\n]\n",temp2);
// 			nomi_output[set.nOutputs+k]=Form("M_%s",temp2);
// 		}		
// 	}
// 	fclose(f);
// 	
// 	
// 	//Preparo file output if STEP1
// 	if(set.STEP==1){
// 		for(int k=0;k<set.nOutputs;k++) nomi_output_fin[k]=nomi_output[k];
// 		for(int j=0;j<set.nSeries_Mtrig;j++){
// 			for(int k=0;k<8;k++){
// 				nomi_output_fin[j*8+set.nOutputs+k]=nomi_output[set.nOutputs+j]+Form(">=%d",k+1);
// 			}
// 		}
// 		for(int k=set.nOutputs+8*set.nSeries_Mtrig;k<32;k++) nomi_output_fin[k]="INACTIVE";
// 	}


   //    printf("bu\n"); exit(-1);
   //istanzio gli array necessari di bottoni e stringhe
   bottoni=new int*[set.nOutputs_LM];
   for(int i=0;i<set.nOutputs_LM;i++){
	bottoni[i]=new int[set.nInputs_LM];
	for(int j=0;j<set.nInputs_LM;j++) bottoni[i][j]=0;
   }
	
   if(set.STEP==2){
	bottoni_out=new int[set.nOutputs_LM];
	bottoni_mask=new int[set.nOutputs_LM];
	reductions=new int[set.nOutputs_LM];
	input_d=new int[set.nRealInputs];
	for(int j=0;j<set.nOutputs_LM;j++){
		 bottoni_out[j]=0;
		 bottoni_mask[j]=0;
		 reductions[j]=1;
	}
	for(int j=0;j<set.nRealInputs;j++) input_d[j]=0;
   }
   printf("Loading setup\n");
   load_values();
}

bool Programma_TBOX_STEP::HandleApply(){
	//LINE();
	printf("Inside Handle_APPLY\n");
	
	// resetto il resettabile
	TrigBox->Init();
	TrigBox->ResetBitPattern();
	
	//elementi della LM
	
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
					codici[count]=bottoni[o][i];
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
					codici[count]=bottoni[o][i];
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
					codici[count]=bottoni[o][i];
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
					codici[count]=bottoni[o][i];
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
					codici[count]=bottoni[o+set.nOutputs][i];
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
					codici[count]=bottoni[o][i];
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
					codici[count]=bottoni[o+set.nOutputs][i];
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
	TrigBox->SetInWidth(input_w/tauclk);
		
	if(set.STEP==2){
		for(int o=0;o<set.nOutputs_LM;o++){
			TrigBox->SetLMOut(o,bottoni_out[o]);
			TrigBox->SetTrigMaskBit(o,bottoni_mask[o]);
			TrigBox->SetTrigReduction(o,reductions[o]);			
		}		
		//delays
		for(int i=0;i<set.nRealInputs;i+=2){
			int val1,val2;
			val1=input_d[i]/tauclk;
			val2=0;
			if(i+1<set.nRealInputs){
				val2=input_d[i+1]/tauclk;
			}
			TrigBox->SetInDelay_128_STEP2(i, val1,val2);
		}		
		
		TrigBox->SetTrigResTime( resolving/tauclk);
		
		TrigBox->SetOutputWidth( output_w/tauclk);
		 
		TrigBox->SetOutputDelay( output_d/tauclk);
	}
	
	TrigBox->SetA395DLogic(nimttl_comb);
    if(set.STEP==2 && TrigBox->IsV2495())TrigBox->SetOutLogic(nimttlout_comb);
	if(set.STEP==1){
		TrigBox->SetOutputOrder_STEP(Order_comb);
	}
	if(set.STEP==2){
		TrigBox->SetOutputConnector_STEP(Main_comb);
	}
	
	Generate_Output_List();
	TrigBox->ResetScale(); // non servirebbe ma male non fa direi...
	bool res=true;
	if(TrigBox->IsV2495()){
		Generate_MemoryMapFile();
		if(!VerifyMemoryFile()){
			 printf("Warning, something went wrong...\n");
			 res=false;
		}
		else printf("Configuration verified\n");
        system("rm TB_memory.map");
	}
//	printf("Exiting\n");
	system("touch /tmp/triggebox_loaded.ok");
//	printf("Exiting\n");
	return res;
	
}

void Programma_TBOX_STEP::Generate_MemoryMapFile(){
	system("rm TB_memory.map");
	FILE *fmap=fopen("TB_memory.map","w");
	fprintf(fmap,"%d %d\n %d %d\n",0x1080,0x9BF,0x1084,TrigBox->GetGeneralFWData());
	
	//Delays (only STEP2)
	int basea=INFNFI2_TBOX_GDGEN_DEL;
	if(set.STEP==2){
		for(int i=0;i<64 && 2*i<set.nRealInputs;i++){
			int temp=0;
			int val1,val2;
			val1=input_d[2*i]/tauclk;
			val2=0;
			if(2*i+1<set.nRealInputs){
				val2=input_d[2*i+1]/tauclk;
			}
			temp=(val2<<8) | val1;
			fprintf(fmap,"%d %d\n",basea,temp);
			basea+=4;
		}		
	}
	
	//Gate width
	fprintf(fmap,"%d %d\n",INFNFI2_TBOX_GDGEN_WID,input_w/tauclk);
	
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
					codici[count]=bottoni[o][i];
					temp=temp| (bottoni[o][i]<<(2*count));
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
					codici[count]=bottoni[o][i];
					temp=temp| (bottoni[o][i]<<(2*count));
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
					codici[count]=bottoni[o][i];
					temp=temp| (bottoni[o][i]<<(count));					
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
					codici[count]=bottoni[o+set.nOutputs][i];
					temp=temp| (bottoni[o+set.nOutputs][i]<<(count));					
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
	if(set.STEP==2){
		//Output 
		for(int i=0;i<set.nOutputs_LM;i++){
			fprintf(fmap,"%d %d\n",INFNFI2_TBOX_LMOUTPUT+4*i,bottoni_out[i]);	
		}
		//bottoni_mask
		int temp=0;
		for(int i=0;i<set.nOutputs_LM;i++){
			temp=temp|(bottoni_mask[i]<<i);
		}
		fprintf(fmap,"%d %d\n",INFNFI2_TBOX_RED_MASK,temp);
		
		//reductions
		for(int i=0;i<set.nOutputs_LM;i++){
			fprintf(fmap,"%d %d\n",INFNFI2_TBOX_REDUCTION+4*i,reductions[i]);	
		}
		fprintf(fmap,"%d %d\n",INFNFI2_TBOX_TRIG_REST,resolving/tauclk);
		fprintf(fmap,"%d %d\n",INFNFI2_TBOX_MAINTR_WID,output_w/tauclk);	
		fprintf(fmap,"%d %d\n",INFNFI2_TBOX_MAINTR_DEL,output_d/tauclk);	
	}
	fclose(fmap);	
}

bool Programma_TBOX_STEP::VerifyMemoryFile(){
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

  void Programma_TBOX_STEP::load_values(){
	  std::ifstream inf;
	  isCP=true;
	  inf.open(SAVE_FILE.Data());
	  if(!inf.is_open()){
		  printf("File not found, aborting!\n");
		  isCP=false;
		  return;
	  }
	  int checkr;
	  inf>>checkr;
	  if(checkr!=TrigBox->GetGeneralFWData()){
		  printf("File not compatible, aborting!\n");
		  isCP=false;
		  return;
	  }
	  std::string temps;
	  TString Ttemps;
	  while(getline(inf,temps)){
		Ttemps=temps;
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
  }
   
  void Programma_TBOX_STEP::read_delays(std::ifstream& input){
		TString temp;
		std::string temps;
		int idX,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps);
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>idX>>bV;
			if(idX<set.nRealInputs){
			 	int iv=(int)(round((double)bV/tauclk))*tauclk;				
				input_d[idX]=iv;
			}
			else printf("Found value of non existing input delay %d\n",idX);
		}	  	  
  }
  
  void Programma_TBOX_STEP::read_LM(std::ifstream& input){
		TString temp;
		std::string temps;
		int bX,bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps);
			if(temp=="#END") break;
			std::istringstream iss(temps);
			iss>>bY>>bX>>bV;
			if(bY<set.nOutputs_LM && bX<set.nInputs_LM) bottoni[bY][bX]=bV;
			else printf("Found status of non existing LM button\n");
		}	  
  }

  void Programma_TBOX_STEP::read_general(std::ifstream& input){
	  TString temp;
	  std::string temps;
	  int idX,bV;
	  while(true){
			getline(input,temps);
			temp=TString(temps);
			if(temp=="#END") break;
			std::istringstream iss(temps);
			iss>>idX>>bV;
			if(idX>7) continue;
			else if(idX==0){
				int iv=(int)(round((double)bV/tauclk))*tauclk;				
				input_w=iv;				
			}
			else if(idX==4){
				nimttl_comb=bV;				
			}
			else if(idX==5 && set.STEP==1){
				Order_comb=bV;
			}			
			else if(idX>0 && set.STEP==2){
				int iv=(int)(round((double)bV/tauclk))*tauclk;				
				if(idX==1) output_w=iv;
				if(idX==2) output_d=iv;
				if(idX==3) resolving=iv;
				if(idX==6) Main_comb=bV;
                if(idX==7 && TrigBox->IsV2495()) nimttlout_comb=bV;
			}
			else printf("Found value of non existing general info\n");			
		}	 	  
  }
  
  void Programma_TBOX_STEP::read_mask(std::ifstream& input){
		TString temp;
		std::string temps;
		int bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps);
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>bY>>bV;
			if(bY<set.nOutputs_LM) bottoni_mask[bY]=bV;
			else printf("Found status of non existing MASK button\n");
		}	 	  
  }
    
  void Programma_TBOX_STEP::read_out(std::ifstream& input){
		TString temp;
		std::string temps;
		int bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps);
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>bY>>bV;
			if(bY<set.nOutputs_LM) bottoni_out[bY]=bV;
			else printf("Found status of non existing OUT button\n");
		}	 	  
  }
  
  void Programma_TBOX_STEP::read_reductions(std::ifstream& input){
		TString temp;
		std::string temps;
		int bY,bV;
		while(true){
			getline(input,temps);
			temp=TString(temps);
			if(temp=="#END") break;
			if(set.STEP!=2) continue;
			std::istringstream iss(temps);
			iss>>bY>>bV;
			if(bY<set.nOutputs_LM) reductions[bY]=bV;
			else printf("Found status of non existing OUT button\n");
		}	 	  
  }
  


void Programma_TBOX_STEP::Generate_Output_List(){
		FILE *f;
	  	if(set.STEP==1){
			f=fopen(set.output_gen.Data(),"w");
			int ioff;
			int iord;
			int ordreg=Order_comb;
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
