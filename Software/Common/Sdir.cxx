
#include <iostream>
#include <fstream>
#include <sys/types.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/file.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/time.h>
#include <math.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <netdb.h>
#include <arpa/inet.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <unistd.h>
#include "Sdir.h"

static int repdir=0;
char HOME[500];
bool homeset=false;
// char FTBOXDIR[500];
// bool tboxset=false;

char* FTBOX_DIR(){
    if(!homeset){
        if((char*) std::getenv("FTBOX_DIR")){
             strcpy(HOME,(char*)std::getenv("FTBOX_DIR"));
        }
        else{
            sprintf(HOME,"%s/FTBOXSAVE",(char*)std::getenv("HOME"));
        }
        homeset=true;        
    }
    return HOME;
}
