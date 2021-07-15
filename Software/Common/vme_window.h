/*
   windows & size definition   (used by FClasses/FVmeControl.cxx  and
                                          vmelib/FVmeControl.cxx

*/
#define WIN0_START_ADDR 0xD0000000  // dsp board D000....DF00  (A32/D16)
#define WIN0_SIZE       0x0F0F0000


//#define WIN1_START_ADDR 0xED000000  // System Controller E000 Caen ADC EE00 (A32/D32)
//#define WIN1_SIZE       0x01100000
//#define WIN1_START_ADDR 0xE0000000  // System Controller E000 Caen ADC EE00 (A32/D32)
#define WIN1_START_ADDR 0xE0000000  // System Controller E000 Caen ADC EE00 (A32/D32)
#define WIN1_SIZE       0x01000000
//#define WIN1_SIZE         0x0E0F0000 // this size can change depending on CPU type

//#define WIN1_START_ADDR 0xEE000000  // System Controller E000 Caen ADC EE00 (A32/D32)
//#define WIN1_SIZE       0x00200000
//#define WIN1_START_ADDR 0xE0000000  // System Controller E000 Caen ADC EE00 (A32/D32)
//#define WIN1_SIZE       0x00200000

#define WIN4_START_ADDR 0xC5000000  // triggerbox (V1495) CFF0 CFF1 (A32/D32)
#define WIN4_SIZE       0x0AFF0000

#define WIN2_START_ADDR 0           // A24 first useful addr 0x10000
#define WIN2_SIZE       0xFF0000 
#define WIN3_START_ADDR 0           // A16 
#define WIN3_SIZE       0xFFFF

#define WIN0_INBOUND_SIZE 0x1000000  // for DMA reading PCI window  maximum allowed 
// this is a limitation due to dma_alloc_coherent() kernel routine, which allows
// a maximum of 1024*PAGE_SIZE(=4096) buffer size.
// It is possible to have a bigger buffer if this is reserved once for all at boot
// that means: driver can't be a module
//             buffer is reserved for ever (maybe this is not a limitation)
// CONFIG_VME_BRIDGE_BOOTMEM has to be defined and kernel rebuilt, then window 7
//                           will be able to remap inbound buffer
//                                                               see driver 

/*        device     window  VME_start    VME_end     size      access

       /dev/vme_m0    0      D0000000     DF010000   0F010000   A32  D16
       /dev/vme_m1    1      E0000000     EE100000   0E100000   A32  D32
       /dev/vme_m2    2      00000000     00900000   00900000   A24  D32
       /dev/vme_m3    3      00000000     0000FFFF   0000FFFF   A16  D32
       /dev/vme_m4    4      C3000000     CFFF0000   0CFF0000   A32  D32

 window 0 for up to 16 D0000000....DF000000  florence mother boards

        1 for          E0000000              Fair System Controller
                       E1000000....EE000000  Caen ADC's
             
        2 for            800000              Caennet Controller
                         880000......8F0000  CBD8210 Branch 1...8 
                                             (do not use Branch 0 or 9  !!!!!,
                                              all programs suppose branch 1)
                         FEEE00              Caen V262 I/O register
             
        3 for              8200              EC738  Hytec  Scalers
             
        4 for          C3000000....CF000000  any apparatus like Caen ADC's
              up to 16 CFF00000....CFFF0000  V1495 general purpose logic  
                                             CFF00000 trigger box
                                             CFF10000 threshold logic 
                                                      (Phoswich,Si)
             
 window 0  /dev/vme_s0   inbound window for dma transfer
             
           /dev/vme_ctl  device for enabling, disabling, polling vme interrupts
             
           /dev/vme_dma0 dma channel 0 for transferring data 
                         (all programs do transfer from VME to PCI->PPCmemory)
                          inbound window can be used as shared buffer where
                          all data are collected and then written to disk
           dma0 is initialized only with windows 0,1,4, for the others has
                                                        to be implemented!!!
*/
