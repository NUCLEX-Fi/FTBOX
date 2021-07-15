
#include <TApplication.h>
#include <GATriggerBoxLA_step.h>

GATriggerBoxLA_step *tbox;

int main(int argc, char** argv){
	LINE();
// 	system("xmessage -timeout 10 -center 'TRIGGERBOX LA LOADING...' &");
	TApplication *a=new TApplication("Trigger Box LA",NULL,NULL);
	int VMEADDR=0xCFF00000;
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
	tbox=new GATriggerBoxLA_step(VMEADDR,fsuff,ll,dd);
	a->Run();
	return 0;	
}
