#include <TriggerBoxGUI_step.h>

void triggerboxgui_step(int VMEADDR,char* fsuff,int Lnk,int Dev){
	LINE();
	new TriggerBoxGUI_step(VMEADDR,fsuff,Lnk,Dev);
}


int main(int argc, char** argv){
	LINE();
	//system("xmessage -timeout 10 -center 'TRIGGERBOX CONTROL LOADING...' &");
    printf("Save dir =%s\n",FTBOX_DIR());
	TApplication *a=new TApplication("acq",NULL,NULL);
	int VMEADDR=0xCFF00000;
    if(argc<3){
#ifndef CAEN_VME_BRIDGE        
      printf("Usage: ./tbox_gui   VMEADDR(hex) TBOX_NAME(str)\n");
#else
      printf("Usage: ./tbox_gui   VMEADDR(hex) TBOX_NAME(str) [LINK_ID(=0)] [DEVICE_ID(=0)]\n");
#endif
      exit(1);        
    }
	if(argc>=2){
		sscanf(argv[1],"%x",&VMEADDR);
	}
	char *fsuff=NULL;
	if(argc>=3) fsuff=argv[2];
    int ll=0;
    int dd=0;
#ifdef CAEN_VME_BRIDGE
    if(argc>=4) ll=atoi(argv[3]);
    if(argc>=5) dd=atoi(argv[4]);
#endif    
	triggerboxgui_step(VMEADDR,fsuff,ll,dd);
    a->Run();
}
