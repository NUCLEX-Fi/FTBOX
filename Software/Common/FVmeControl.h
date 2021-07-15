/*
  $Header: /home/CVS/luigi/FClasses/FVmeControl.h,v 1.14 2017-06-05 09:20:34 garfield Exp $
  $Log: FVmeControl.h,v $
  Revision 1.14  2017-06-05 09:20:34  garfield
  FVme*: mods to compile with CAEN_VMEBRIDGE on a 64bit system
  do_manymap: Bug fixed (.h files in rootmap)

  Revision 1.13  2014-07-31 14:54:54  garfield
  FVme* classes now compatible with CAEN VMEBRIDGE. Succesfully
  acquired signals from GARFIELD MoBo with old daugther boards.

  Revision 1.12  2014-07-30 10:29:36  garfield
  First version handling CAEN VME BRIDGE

  Revision 1.11  2014-07-26 09:55:26  garfield
  Modificate macro dsp_IO, dsp_STAT, dsp_END etc. per compatibilità con
  accesso da CAEN VME BRIDGE

  Revision 1.10  2010-11-16 13:36:45  bini
  working version with new driver: new DMA initialization with window 7
  statically created at boot time

  Revision 1.9  2010/09/21 10:54:41  bini
  new WIN size and start address (vme_window.h), same file to be
  included in vmelib

  Revision 1.8  2010/09/17 10:53:17  bini
  all vme classes MVME5100 6100 7100 compatible with new universe-tsi148
  driver

  Revision 1.7  2009/07/08 07:14:20  bini
  new upgrades for MVME6100

  Revision 1.6  2009/07/07 09:24:25  bini
  MVME6100 features added

  Revision 1.5  2008/11/03 16:15:30  bini
  some correction done during fazia run or for caen V17xx boards

  Revision 1.4  2007/08/10 10:49:00  bini
  in FVmeDsp new UNzip routine for compact signals and few routines
  for reading via DMA without waiting

  Revision 1.3  2007/05/24 14:13:24  bini
  aggiornate FVmexxx per 2191

  Revision 1.2  2006/05/05 13:10:26  bardelli
  Aggiunto Header e Log in testa a tutti i files

*/

/*********** CHECK FOR VME CPUs!!! **************/
#if defined (MVME5100) || defined (MVME2400) || defined (MVME6100) || defined (MVME7100) || defined (CAEN_VME_BRIDGE)
/************************************************/


#ifndef NOROOT
#include <TObject.h>
#endif
//#if defined (MVME6100) || defined (MVME7100)

#ifndef CAEN_VME_BRIDGE
#include <vmedrv.h> //header file del driver vmelinux
#endif
//#endif

#ifndef FIASCO_FVmeControl
#define FIASCO_FVmeControl

#ifdef CAEN_VME_BRIDGE
#define LINUX
#include "CAENVMElib.h"
#endif

#ifndef NOROOT
class FVmeControl: public TObject{
#else
class FVmeControl {
#endif
public: 
/* 
   returned value   -1 open not permitted
                    -2 ioctl wrong value
            vme_handle  ok some other program has  done
                        tundra programming
            vme_handle  ok this program does tundra setting

   inbound window is set firmly to 0
*/

  FVmeControl();
  virtual ~FVmeControl();

#ifndef CAEN_VME_BRIDGE
  FVmeControl(int d32);

  void *  VmeMapMem(unsigned int size, unsigned int phys_addr);

  void  VmeUnmapMem(unsigned int size, unsigned int mmap_addr);
  int Getvme_handle() const { return vme_handle;};
  vmeDmaPacket_t *Get_vmeDmapacket()  { return &vmeDma;};
#else
  FVmeControl(int idLink,int idDevice);
#endif

#ifdef CAEN_VME_BRIDGE
  void vmebridge_writeshort(uint32_t address, unsigned short data);
  unsigned short vmebridge_readshort(uint32_t address);
  void vmebridge_writeint(uint32_t address, uint32_t data);
  uint32_t vmebridge_readint(uint32_t address);  
#endif




protected:
#ifndef CAEN_VME_BRIDGE
  vmeDmaPacket_t vmeDma;
  int vme_handle; // tundra file descriptor
  void InitializeDMA(int d32);
  int configure_vmechip(int d32,unsigned int vme_address);
#endif
#ifdef CAEN_VME_BRIDGE
  CVBoardTypes  VMEBoard;
  short         Link;
  short         Device;
  int32_t       vme_handler;
#endif
#ifndef NOROOT
  ClassDef(FVmeControl,1) // FIASCO: Class for storing and manipulating ADC events
#endif
};

/***************************************************************************/


#endif




#endif /* end of #if defined (MVME5100) || defined (MVME2400) */
