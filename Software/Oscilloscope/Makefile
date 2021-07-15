ROOTSYS=$(shell root-config --prefix)/root

#CHECK_ROOT6 = $(shell echo "gROOT->GetVersion()" | root -l | grep -v Autoloading | grep -c "6\.")
CHECK_ROOT6 = $(shell root-config --version | grep -c "6\.")
ROOT-CONFIG=$(shell root-config --bindir)/root-config
ROOTINT =rootcint
ifeq ($(CHECK_ROOT6) ,1)
	ROOTINT =rootcling
endif



######### ATTENZIONE AL -pipe.....
OPTIMIZE = -O3 -pipe -fkeep-inline-functions -fPIC

## c'e' un baco con gcc 3.2: con questo truccaccio sembra andare a posto...
OPTIMIZE += $(shell  gcc -v 2>1 ; cat 1 | grep "version 3.2" >/dev/null && echo "-fschedule-insns"; rm -f 1)


GCC_FPMATH=$(shell echo > /tmp/test_ssesupport.C ; gcc -mfpmath=387 /tmp/test_ssesupport.C -c -o /dev/null 2>/dev/null && echo YES; rm -f /tmp/test_ssesupport.C)

ARCH=$(shell echo > /tmp/test_archsupport.C ; gcc -march=native /tmp/test_archsupport.C -c -o /dev/null 2>/dev/null && echo YES; rm -f /tmp/test_archsupport.C)


ifeq ($(ARCH),YES)
	GCC_FPMATH=NO
## con march=native cubic non funza!?
	OPTIMIZE +=  -march=native 
endif

ifeq ($(GCC_FPMATH),YES)
	OPTIMIZE +=$(shell grep sse /proc/cpuinfo >/dev/null && echo  -msse -mfpmath=sse)
	OPTIMIZE +=$(shell grep sse2 /proc/cpuinfo >/dev/null && echo  -msse2 -mfpmath=sse)
endif



#COMPILER = g++ -std=c++11 -Wall  -pipe 
COMPILER = g++  -Wall  -pipe 
USE_SSE=$(shell echo \"$(OPTIMIZE)\" | grep mfpmath)

## non serve + :
#FIASCO_INCLUDE=$(shell pwd)
ROOTSYS ?=$(shell $(ROOT-CONFIG) --prefix)


CAEN_VMELIB=
#### check for CAEN Digitizer Library, needed by FCAENDigitizer ####
ifneq ($(shell ls /usr/lib | grep CAENVME),)
CAEN_VMELIB=-lCAENVME
$(warning "WARNING: Using CAENVME lib  !!")
endif

#CAEN_LIB=
#### check for CAEN Digitizer Library, needed by FCAENDigitizer ####
#ifneq ("$(wildcard $(/usr/lib/libCAENDigitizer.so))","")
#CAEN_LIB=-lCAENDigitizer
#endif

ifneq ($(USE_SSE),)
$(warning "WARNING: Using SSE optimizations  !!")
endif


#ROOT_INCLUDE  =/usr/include/root
ROOT_INCLUDE =$(shell $(ROOT-CONFIG) --incdir)
#ROOT_LIB      =/usr/lib
ROOT_LIB =$(shell $(ROOT-CONFIG) --libdir)
#ROOTCINT      =/usr/bin/rootcint
ROOTCINT =$(shell $(ROOT-CONFIG) --bindir)/$(ROOTINT)
ROOTLIBS =$(shell $(ROOT-CONFIG) --glibs)
ROOTFLAGS =$(shell $(ROOT-CONFIG) --cflags)
# COMPILER +=$(shell $(ROOT-CONFIG) --cflags)

INCLUDE=-I$(ROOT_INCLUDE) -I. -I../Common
# 
# # remove comment to use ARC SPLINE (libgsl0-dev  must be installed and
# # root must be reconfigured to compile libMathMore)
# # INCLUDE+= -DUSE_ARC_SPLINE
# 
# ## per usare questa funzione bisogna che il target COINCIDA col SOLO nome della classe.so
# ## ad esempio FSignal.so NON FSignal FSignal.c++ o altro, e che inoltre i vari
# ## file di link FSignal.h FSignal.cxx FSignalLinkDef.h siano ok.
# ## $@ rappresenta il target...
# ##
# ## togliere i "@" per vedere i comandi
# ##
# 
# ##########################################################
# ##########################################################
# ##
# ## per aggiungere una nuova classe basta metterla in questo elenco qui :-))
# ##
# 
# ##########################################################
# ############# CPU DETECTION: VME? ########################
# ##########################################################
# ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 2400),)
# 	COMPILER += -DMVME2400
# 	ROOTCINT_DEFINES += -DMVME2400
# endif
# ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 5100),)
# 	COMPILER += -DMVME5100
# 	ROOTCINT_DEFINES += -DMVME5100
# endif
# ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 6100),)
# 	COMPILER += -DMVME6100
# 	ROOTCINT_DEFINES += -DMVME6100
# endif
# ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 7100),)
# 	COMPILER += -DMVME7100
# 	ROOTCINT_DEFINES += -DMVME7100
# endif
# # solo per provare!!!
# ifneq ($(shell ls /usr/lib | grep CAENVME),) 
# #$(warning "WARNING: no CAENVME lib will be used NO CAEN_VME_BRIDGE!!")
# $(warning "WARNING: Using CAENVME lib: defining  CAEN_VME_BRIDGE!!")
# 	COMPILER += -DCAEN_VME_BRIDGE
# 	ROOTCINT_DEFINES += -DCAEN_VME_BRIDGE
# 	#SHAREDS +=  FVmeControl.so FVmeTrigBox.so
# endif
# 
# ##########################################################
# ##########################################################
# export
# 
# all:    
# 	@ echo "using ROOT found in $(ROOTSYS) ..."
# #	@ ${MAKE} depend 
# 	@ echo "Building Dictionary"
# 	@ ${MAKE} GUIDict.cxx
# 	@ echo "Building Executable"
# 	@ ${MAKE} tbox_gui
# 	#@ ${MAKE} $(LIBFIASCO).rootmap dbedit_dsp.out fair_dispatcher.out
# #	-@ make docs
# 	#@echo "per generare la documentazione: make docs"
# 	#@ ls -l $(LIBFIASCO).so  dbedit_dsp.out fair_dispatcher.out
# 	#@ echo " ################### Done.####################"


#	- @echo ">>>>>>> Controllo versione: " $(shell cat   $(subst .so,.h,$(SHAREDS))  $(subst .so,.cxx,$(SHAREDS)) > /tmp/version.C ; md5sum /tmp/version.C  | sed s/" .*"//g; rm -f /tmp/version.C)
	#@echo
# 
# clean:
# 	- rm -f *~ $(SHAREDS) $(subst .so,.o,$(SHAREDS))  
# 
# GUIDict.cxx: TriggerBoxGUI_step.h TriggerBoxGUI_stepLinkDef.h
# 	@ $(ROOTCINT) -f GUIDict.cxx $(INCLUDE) -c $(ROOTCINT_DEFINES) -p TriggerBoxGUI_step.h TriggerBoxGUI_stepLinkDef.h
# 
# tbox_gui: TriggerBoxGUI_step.cxx GUIDict.cxx triggerboxgui_step.C
# 	@ $(COMPILER) $(OPTIMIZE) $(INCLUDE) $(CAEN_LIB) $(ROOTLIBS) -lCommon -L../Common TriggerBoxGUI_step.cxx GUIDict.cxx triggerboxgui_step.C -o tbox_gui
# 
# 
	
	
	
	
	
	
	

CPP=g++ -O3 -Wall -I. 
CC=gcc
#LIB=/home/bini/fair/DEVEL/DAQ

ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 2400),)
        CPP += -DMVME2400
	CC  += -DMVME2400
	ROOTCINT_DEFINES += -DMVME2400
	found = 1
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 5100),)
        CPP += -DMVME5100
	CC  += -DMVME5100
	ROOTCINT_DEFINES += -DMVME5100
	found = 1
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 6100),)
        CPP += -DMVME6100
	CC  += -DMVME6100
	ROOTCINT_DEFINES += -DMVME6100
	found = 1
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 7100),)
        CPP += -DMVME7100
	CC  += -DMVME7100
	ROOTCINT_DEFINES += -DMVME7100
	found = 1
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 4100),)
        CPP += -DMVME4100
	CC  += -DMVME4100
	ROOTCINT_DEFINES += -DMVME4100
	found = 1
endif
ifneq ($(shell ls /usr/lib | grep CAENVME),) 
#$(warning "WARNING: no CAENVME lib will be used NO CAEN_VME_BRIDGE!!")
$(warning "WARNING: Using CAENVME lib: defining  CAEN_VME_BRIDGE!!")
	found = 1
	CPP += -DCAEN_VME_BRIDGE
	CC += -DCAEN_VME_BRIDGE
	ROOTCINT_DEFINES += -DCAEN_VME_BRIDGE
	#SHAREDS +=  FVmeControl.so FVmeTrigBox.so
endif
ifndef found
        CPP += -DNO_VME_CPU
	CC  += -DNO_VME_CPU
endif

CPP +=  -I../Common $(CAEN_VMELIB) -I. -L. -L../Common -lFTBOX

all:  
	#make depend
	make tbox_la
	@echo "=========== OK ============="
# 	rm -f *.o *Dict* 
	cp tbox_la ../bin/ftbox_oscilloscope
# 	ls -l *out

################# SLAVE ##############################

clean:
	- rm -f *.o *Dict* tbox_la

# 
# %.cxx: NAME=$(subst Dict.cxx,,$@)
# %.cxx: #$(NAME).cxx $(NAME).h
# 	- rm -f $(NAME)Dict.cxx $(NAME)Dict.h
# 	cat VuotoLinkDef.h | sed s="Vuoto"="$(NAME)"=g > $(NAME)LinkDef.h
# 	$(ROOTCINT)  $(NAME)Dict.cxx -c -I.  -I../Common  -p $(NAME).h $(NAME)LinkDef.h
# 	- rm $(NAME)LinkDef.h
# 
# %.o: %.cxx %.h
# 	$(CPP)  `root-config --cflags` $< -c -o $@
# %.o: %.C 
# 	$(CPP)  `root-config --cflags` $< -c -o $@

#garfield_acq.out: garfield_acq.o MainGUI.o InputDialog.o $(SLAVE) $(SCALELIB) $(LIB)/configure_tundra24.o $(LIB)/configure_tundra_DMA.o MyProgress.o sharedmem.h 

GATriggerBoxLA_stepDict.o: GATriggerBoxLA_step.h GATriggerBoxLA_step.cxx
	@ - rm -f *Dict*
	@ $(ROOTCINT) GATriggerBoxLA_stepDict.cxx  -c $(ROOTCINT_DEFINES) -I../Common -p GATriggerBoxLA_step.h GATriggerBoxLA_stepLinkDef.h
	@ $(CPP) $(ROOTFLAGS) $(OPTIMIZE) $(INCLUDE) -c GATriggerBoxLA_stepDict.cxx
	
# TriggerBoxGUI_stepDict.o: TriggerBoxGUI_stepDict.cxx 
GATriggerBoxLA_step.o: GATriggerBoxLA_step.cxx   GATriggerBoxLA_step.h 
	 $(CPP) $(ROOTFLAGS) $(OPTIMIZE) $(INCLUDE) -c GATriggerBoxLA_step.cxx

triggerboxla_step.o: triggerboxla_step.C
	 $(CPP) $(ROOTFLAGS) $(OPTIMIZE) $(INCLUDE) -c triggerboxla_step.C
	 
tbox_la: triggerboxla_step.o GATriggerBoxLA_step.cxx  GATriggerBoxLA_step.h GATriggerBoxLA_stepDict.o
#	make TriggerBoxGUI_stepDict.cxx 
	make GATriggerBoxLA_stepDict.o
	make GATriggerBoxLA_step.o
	$(CPP) $(ROOTFLAGS) $(ROOTLIBS) GATriggerBoxLA_stepDict.o GATriggerBoxLA_step.o triggerboxla_step.o ../Common/Sdir.o -o $@
	
