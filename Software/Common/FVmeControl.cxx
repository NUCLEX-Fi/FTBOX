/*
  $Header: /home/CVS/luigi/FClasses/FVmeControl.cxx,v 1.22 2017-06-05 09:20:34 garfield Exp $
  $Log: FVmeControl.cxx,v $
  Revision 1.22  2017-06-05 09:20:34  garfield
  FVme*: mods to compile with CAEN_VMEBRIDGE on a 64bit system
  do_manymap: Bug fixed (.h files in rootmap)

  Revision 1.21  2014-07-31 14:54:54  garfield
  FVme* classes now compatible with CAEN VMEBRIDGE. Succesfully
  acquired signals from GARFIELD MoBo with old daugther boards.

  Revision 1.20  2014-07-30 10:29:36  garfield
  First version handling CAEN VME BRIDGE

  Revision 1.19  2013-09-23 16:19:32  bini
  with Bo card control

  Revision 1.18  2010/11/16 13:36:45  bini
  working version with new driver: new DMA initialization with window 7
  statically created at boot time

  Revision 1.17  2010/09/21 10:54:41  bini
  new WIN size and start address (vme_window.h), same file to be
  included in vmelib

  Revision 1.16  2010/09/17 10:53:17  bini
  all vme classes MVME5100 6100 7100 compatible with new universe-tsi148
  driver

  Revision 1.15  2010/04/26 10:25:02  bini
  Nuova scheda trigger box VHDL gabriele
  fix vari

  Revision 1.14  2010/04/14 08:02:27  bini
  few updates for MVME6100

  Revision 1.13  2009/07/08 07:14:20  bini
  new upgrades for MVME6100

  Revision 1.12  2009/07/07 09:24:25  bini
  MVME6100 features added

  Revision 1.11  2009/06/24 07:25:37  bini
  *** empty log message ***

  Revision 1.10  2009/06/24 07:24:33  bini
  *** empty log message ***

  Revision 1.9  2009/06/24 07:17:05  bini
  *** empty log message ***

  Revision 1.7  2008/11/03 16:15:30  bini
  some correction done during fazia run or for caen V17xx boards

  Revision 1.6  2007/08/10 10:49:00  bini
  in FVmeDsp new UNzip routine for compact signals and few routines
  for reading via DMA without waiting

  Revision 1.5  2007/08/03 09:10:21  bini
  host port DMA reading implemented in FVmeDsp.cxx
  Vme interrupt enable  in FVmeControl24.cxx

  Revision 1.4  2007/05/24 14:13:24  bini
  aggiornate FVmexxx per 2191

  Revision 1.3  2006/05/05 15:06:47  bini
  aggiunto FVmeControl24 e sincronizzato con vmefi6

  Revision 1.2  2006/05/05 13:10:26  bardelli
  Aggiunto Header e Log in testa a tutti i files

*/

/*********** CHECK FOR VME CPUs!!! **************/
#if defined (MVME5100) || defined (MVME2400) || defined (MVME6100) || defined (MVME7100) || defined (CAEN_VME_BRIDGE)
/************************************************/

#define PREN       (1 << 29)
#define PGM_DATA   (1 << 22)
#define PGM_PRGM   (1 << 23)
#define PGM_BOTH   (3 << 22)
#define SUPER_NO   (1 << 20)
#define SUPER_YES  (1 << 21)
#define SUPER_BOTH (3 << 20)
#define LD64EN     (1 << 7)
#define LLRMW      (1 << 6)
#define LAS_IO     1
#define LAS_CONF   2
#define IM_EN    (1 << 31)
#define PWEN     (1 << 30)
#define VDW_32   (1 << 23)  /*means 32 bit data with */
#define VDW_08    0x00      /*means  8 bit data with */
#define VDW_16   (1 << 22)  /*means 16 bit data with */
#define VDW_64   (3 << 22)  /*means 64 bit data with */
#define VAS_A16   0x0
#define VAS_A24   0x10000
#define VAS_A32   0x20000
#define VAS_CR    0x50000
#define VAS_USER1 0x60000
#define VAS_USER2 0x70000
#define PGM       (1 << 14)
#define SUPER     (1 << 12)
#define VCT_BLT   (1 << 8)

#define CTL_EN		      0x80000000

#define IOCTL_SET_CTL 	0xF001
#define IOCTL_SET_BS	  0xF002
#define IOCTL_SET_BD	  0xF003
#define IOCTL_SET_TO	  0xF004
#define IOCTL_SET_MODE 	0xF006

#define MODE_PROGRAMMED 0x01
#define MODE_DMA        0x02


 /*  if ( addr(PPC) > XSADD2(start) &&
          addr(PPC) < XSADD2(stop) )
     then  addr(PCI) = addr(PPC) + XSOFF2
     Ex: addr(PPC) = d0000000 (XSADD2(start)=c0000000
                               XSADD2(stop) =fcff0000
                               XSOFF2       =40000000)
         addr(PCI) = d0000000 + 40000000 = 10000000   
     if (addr(PCI) > LOWESTn && addr(PCI) < BOUNDn)
     then  addr(VME) = addr(PCI) + TOFFSETn
     Ex: addr(PCI) = 10000000 (LOWEST1 = 10000000
                               BOUND1  = 32000000
                               TOFFSET1= c0000000)
     addr(VME) = 10000000 + c0000000 = d0000000

  PCI target Image 1 for 32bit Address
  on PPC addr between d0000000 and f2000000
  on PCI addr between 10000000 and 32000000
  on VME addr between d0000000 and f2000000  */
/* for mvme2400 with prep  BUG4 */  
#ifdef MVME2400
#define VME_LOWEST1  0x10000000      
#define VME_BOUND1   0x32000000
#define VME_TOFFSET1 0xc0000000
/* 24 bit addressing should be from FD000000 to FDFFFFFF */
/*     */
#define VME_LOWEST2  0x00000000     
#define VME_BOUND2   0x01000000
#define VME_TOFFSET2 0x00000000

#endif

/* for MVME5100  with chrp  BUG6 */
/*  ATTENZIONE ho trovato una limitazione alla size??
    se SIZE > 1C000000 (VME_BOUND1-VME_LOWEST1) ioremap
    nel driver (ioctl (set_bs)) risponde con 0  
    mi sembra lo faccia la cpu MVME5100 con 512 MB di RAM e
    non quella con 64 MB 
*/ 
#ifdef MVME5100
/*
  these values for LNS run June 2009 Nov 2009 for Caen V1720

 #define VME_LOWEST0  0xEE000000      
 #define VME_BOUND0   0xEF000000 */
/* these values for Ganil run May 2010 V1495 TriggerBox added
   we do not use V1720, but in case change V1720 addr to CC000000
   instead EE000000.
   At address CFF0000 there is V1495 */
#define VME_LOWEST0  0xC0000000      
#define VME_BOUND0   0xCFFFFFFF 
#define VME_TOFFSET0 0x00000000

#define VME_LOWEST1  0xD0000000      
 
 //#define VME_BOUND1   0xEC000000
#define VME_BOUND1   0xE0000000  /* 0xEB000000  */
#define VME_TOFFSET1 0x00000000
/* 24 bit addressing should be from A0000000 to A0FFFFFF */
#define VME_LOWEST2  0xA0000000
#define VME_BOUND2   0xA2000000  /* this has to be defined in FVmeControl24.cxx
                                    we have to put the definitions in a include
                                    file  !!!!!!!!!!!!!! */
#define VME_TOFFSET2 0x60000000


#endif
/*#define VME_LOWEST1  0xd0000000      
  #define VME_BOUND1   0xf3000000
  #define VME_TOFFSET1 0x00000000
*/
/*#define VME_LOWEST1  0x40000000     
  #define VME_BOUND1   0x60000000
  #define VME_TOFFSET1 0x00000000
*/
#ifndef MVME2400
#ifndef MVME5100
#ifndef MVME6100
#ifndef MVME7100
#ifndef CAEN_VME_BRIDGE
#error "*****************************************"
#error "You have to specify -DMVE2400 or -DMVME5100 or -DMVME6100 or -DMVME7100 or -DCAEN_VME_BRIDGE"
#error "*****************************************"
#endif
#endif
#endif
#endif
#endif
 
#define CTL_EN		      0x80000000



#include <math.h>
#include <stdlib.h>     
#include <unistd.h>

#include <errno.h>
#include <unistd.h>



#ifndef __CINT__
#include <ctype.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/mman.h>
#include <sys/file.h>
//#if defined (MVME6100) || defined (MVME7100)

#ifndef CAEN_VME_BRIDGE
#include <vmedrv.h> //header file del driver vmelinux
#endif
//#endif
#endif

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


#include "FVmeControl.h"
#include "vme_window.h"

#ifndef NOROOT
ClassImp(FVmeControl);
#endif
  FVmeControl::FVmeControl(){
#ifndef CAEN_VME_BRIDGE
    vme_handle = configure_vmechip(16,WIN0_START_ADDR);
    InitializeDMA(16); 
#endif
#ifdef CAEN_VME_BRIDGE
    VMEBoard = cvV2718;
    Link     = 0;
    Device   = 0;

    //Open the connection with V2718 bridge using the optical link
    if( CAENVME_Init(VMEBoard, Device, Link, &vme_handler) != cvSuccess ){
      printf("\n Error opening the device\n"); exit(1);
      }
      else printf("\n Bridge Device: link OK\n");
  

#endif

 };

#ifndef CAEN_VME_BRIDGE
  FVmeControl::FVmeControl(int d32){
    unsigned int vme_address=WIN0_START_ADDR;
    if(d32%100 == 16) vme_address=WIN0_START_ADDR;
    // window 1  A32 D32
    else if(d32/100 == 1 && d32%100 == 32) vme_address=WIN1_START_ADDR;
    // window 4  A32 D32
    else if(d32/100 == 4 && d32%100 == 32) vme_address=WIN4_START_ADDR;
    vme_handle = configure_vmechip(d32,vme_address);
    InitializeDMA(32); 
 };


  void *  FVmeControl::VmeMapMem(unsigned int size, unsigned int phys_addr){
     return (void *)mmap(NULL,size,PROT_WRITE|PROT_READ,MAP_SHARED,vme_handle,phys_addr);
  }

  void  FVmeControl::VmeUnmapMem(unsigned int size, unsigned int mmap_addr){
    munmap((void *)mmap_addr,size);
  }
#else
  FVmeControl::FVmeControl(int idLink,int idDevice){
       VMEBoard = cvV2718;
       Link     = idLink;
       Device   = idDevice;

       //Open the connection with V2718 bridge using the optical link
     if( CAENVME_Init(VMEBoard, Device, Link, &vme_handler) != cvSuccess ){
       printf("\n Error opening the device\n"); exit(1);
       }
       else printf("\n Bridge Device: link OK\n");
   }

#endif


  FVmeControl::~FVmeControl(){ 
#ifndef CAEN_VME_BRIDGE
       printf("Closing tundra\n");    
       close(vme_handle);
#endif
#ifdef CAEN_VME_BRIDGE
     CAENVME_End(vme_handler);
#endif

};

#ifndef CAEN_VME_BRIDGE
int FVmeControl::configure_vmechip(int data_width,unsigned int vme_address)
 {
#ifndef __CINT__
   struct vmeOutWindowCfg vmeOutSet;	 	
 /*
  * addresses and ctrl for each addr window with Tundra as Master
  * set  VME_IOCTL_SET_OUTBOUND 
 */ 
   int DataWidth=data_width%100;
   memset(&vmeOutSet, 0, sizeof(vmeOutSet));
   if (DataWidth == 16)
     {
      if ((vme_handle=open("/dev/vme_m0",O_RDWR,0)) < 0)
       {
        if (errno == EBUSY)
	  {
           if ((vme_handle=open("/dev/vme_m0",O_RDONLY,0)) < 0)
             {
               perror("open readonly /dev/vme_m0 tsi148");
	       return -1;
             }
	  }
        else
	  {
           perror("open tsi148");
           return -1;
          }
       }						
      printf("WARNING: only memory cards >= 0xD0000000 and <= 0xDF010000\n");
      printf("         open TSI148 VME_SCT (%2.2d)bit data\n",DataWidth);
 
      vmeOutSet.windowNbr = 0;	
      vmeOutSet.windowEnable = 1;			 
      vmeOutSet.windowSizeL = WIN0_SIZE;
   /* dimensions as Tundra MVME5100 from C0000000 to EC000000 */
      vmeOutSet.xlatedAddrU = 0x00000000; /* address 63:32 bits */		
      vmeOutSet.xlatedAddrL = vme_address; /*         31:0  bits */
     }
   else if (data_width == 132)   
     {
      if ((vme_handle=open("/dev/vme_m1",O_RDWR,0)) < 0)
       {
        if (errno == EBUSY)
	  {
           if ((vme_handle=open("/dev/vme_m1",O_RDONLY,0)) < 0)
             {
               perror("open readonly /dev/vme_m1 tsi148");
	       return -1;
             }
	  }
        else
	  {
           perror("open /dev/vme_m1  tsi148");
           return -1;
          }
       }						
      printf("WARNING: only memory cards >= 0xE0000000 and < 0xEE100000\n");
      printf("         open TSI148 VME_SCT (%2.2d)bit data\n",DataWidth);
 
      vmeOutSet.windowNbr = 1;	
      vmeOutSet.windowEnable = 1;			 
      vmeOutSet.windowSizeL = WIN1_SIZE;
   /* dimensions as Tundra MVME5100 from C0000000 to EC000000 */
      vmeOutSet.xlatedAddrU = 0x00000000; /* address 63:32 bits */		
      vmeOutSet.xlatedAddrL = vme_address; /*         31:0  bits */
     }
   else if (data_width == 432)   
     {
      if ((vme_handle=open("/dev/vme_m4",O_RDWR,0)) < 0)
       {
        if (errno == EBUSY)
	  {
           if ((vme_handle=open("/dev/vme_m4",O_RDONLY,0)) < 0)
             {
               perror("open readonly /dev/vme_m4 tsi148");
	       return -1;
             }
	  }
        else
	  {
           perror("open /dev/vme_m4  tsi148");
           return -1;
          }
       }						
      printf("WARNING: only memory cards > 0xC3000000 and < 0xCFFF0000\n");
      printf("         CAEN V1495  trigbox (0xCFF00000) silitrig (0xCFF10000)\n");
      printf("         open TSI148 VME_SCT (%2.2d)bit data\n",DataWidth);
 
      vmeOutSet.windowNbr = 4;	
      vmeOutSet.windowEnable = 1;			 
      vmeOutSet.windowSizeL = WIN4_SIZE;
   /* dimensions as Tundra MVME5100 from C0000000 to EC000000 */
      vmeOutSet.xlatedAddrU = 0x00000000; /* address 63:32 bits */		
      vmeOutSet.xlatedAddrL = vme_address; /*         31:0  bits */
     }
   else
    {
     printf("DataWidth=%d not allowed !!!!!!!!!!!\n",DataWidth);
     return -1;
    }    

   vmeOutSet.xferRate2esst = VME_SSTNONE;	      /* clock enable for 2eSST asyncronous transfer */ 
   vmeOutSet.addrSpace = VME_A32;
   vmeOutSet.maxDataWidth = (dataWidth_t)DataWidth;	       
   vmeOutSet.xferProtocol = VME_SCT;
   vmeOutSet.userAccessType = VME_USER; 
   vmeOutSet.dataAccessType = VME_DATA;

   if(ioctl(vme_handle, VME_IOCTL_SET_OUTBOUND, &vmeOutSet)<0)
     { 
      perror(Form(" VME_IOCTL_SET_OUTBOUND failed on Window %d\n",vmeOutSet.windowNbr));   
      if(errno == ENXIO)
	{
	  printf("Window %d already opened by another process:\naddress, offset and limit fixed by first running process\n",vmeOutSet.windowNbr);
         }
      else
        return -1;
     }
#endif
  return vme_handle;	
}


void FVmeControl::InitializeDMA(int d32)
{
#ifndef __CINT__
     memset(&vmeDma,0,sizeof(vmeDma));
     vmeDma.channel_number = 0;
     vmeDma.maxPciBlockSize = 8192;  /*8192;*/
     vmeDma.maxVmeBlockSize = 8192;  /*8192;*/
     vmeDma.vmeBackOffTimer = 0;
/*
   Impostazioni della struttura	from
*/
	vmeDma.srcBus = VME_DMA_VME; 			//Bus sorgente VME
        if(d32==16)
	  {
	   vmeDma.srcVmeAttr.maxDataWidth = VME_D16;	
           vmeDma.srcVmeAttr.xferProtocol = VME_SCT;   // con le schede DSP ci vuole SCT
          }
        else
	  {
	   vmeDma.srcVmeAttr.maxDataWidth = VME_D32;	
           vmeDma.srcVmeAttr.xferProtocol = VME_SCT;   // si migliora con VME_BLT?
          }          
	vmeDma.srcVmeAttr.addrSpace = VME_A32; 	 
	vmeDma.srcVmeAttr.userAccessType = VME_USER;  
	vmeDma.srcVmeAttr.dataAccessType = VME_DATA;	
/*
   Protocollo di trasferimento MBLT,2eVME,2eSST hanno 64 bit per i dati
   ma non bisogna cambiare maxDataWidth=VME_D32
*/
/*
   Impostazioni della struttura to
*/
       	vmeDma.dstBus = VME_DMA_PCI;		     //Bus destination PCI  
        if(d32==16)
	  {
	   vmeDma.dstVmeAttr.maxDataWidth = VME_D16;	
           vmeDma.dstVmeAttr.xferProtocol = VME_SCT;   // con le schede DSP ci vuole SCT
          }
        else
	  {
	   vmeDma.dstVmeAttr.maxDataWidth = VME_D32;	
           vmeDma.dstVmeAttr.xferProtocol = VME_SCT;   // si migliora con VME_BLT?
          }          
	vmeDma.dstVmeAttr.addrSpace = VME_A32;	
	vmeDma.dstVmeAttr.userAccessType = VME_USER;
	vmeDma.dstVmeAttr.dataAccessType = VME_DATA;
/*
   Protocollo di trasferimento MBLT,2eVME,2eSST hanno 64 bit per i dati
   ma non bisogna cambiare maxDataWidth=VME_D32
*/
      
#endif
}


#endif
// here ends the VME CPU part
// and starts the CAEN bridge part
#ifdef CAEN_VME_BRIDGE

void FVmeControl::vmebridge_writeshort(uint32_t address, unsigned short data)
{ 
  CAENVME_WriteCycle(vme_handler,(uint32_t)address,&data,cvA32_U_DATA,cvD16);
}


unsigned short FVmeControl::vmebridge_readshort(uint32_t address)
{
  unsigned short data = 0;
  CAENVME_ReadCycle(vme_handler,(uint32_t)address,&data,cvA32_U_DATA,cvD16);
  return data;
}

void FVmeControl::vmebridge_writeint(uint32_t address, uint32_t data)
{ 
  CAENVME_WriteCycle(vme_handler,(uint32_t)address,&data,cvA32_U_DATA,cvD32);
}


uint32_t FVmeControl::vmebridge_readint(uint32_t address)
{
  uint32_t data = 0;
  CAENVME_ReadCycle(vme_handler,(uint32_t)address,&data,cvA32_U_DATA,cvD32);
  return data;
}

#endif



/***************************************************************************/


#endif
