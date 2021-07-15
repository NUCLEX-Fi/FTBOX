
ROOTSYS=$(shell root-config --prefix)/root

#CHECK_ROOT6 = $(shell echo "gROOT->GetVersion()" | root -l | grep -v Autoloading | grep -c "6\.")
CHECK_ROOT6 = $(shell root-config --version | grep -c "6\.")
ROOT-CONFIG=$(shell root-config --bindir)/root-config
ROOTINT =rootcint
ifeq ($(CHECK_ROOT6),1)
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
# COMPILER +=$(shell $(ROOT-CONFIG) --cflags)
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

INCLUDE=-I$(ROOT_INCLUDE) -I.

# remove comment to use ARC SPLINE (libgsl0-dev  must be installed and
# root must be reconfigured to compile libMathMore)
# INCLUDE+= -DUSE_ARC_SPLINE

COMMONDEP=gcc3_fixes.h

## per usare questa funzione bisogna che il target COINCIDA col SOLO nome della classe.so
## ad esempio FSignal.so NON FSignal FSignal.c++ o altro, e che inoltre i vari
## file di link FSignal.h FSignal.cxx FSignalLinkDef.h siano ok.
## $@ rappresenta il target...
##
## togliere i "@" per vedere i comandi
##
define COMPILA
	@ - rm -f $(subst .so,,$@).so $(subst .so,,$@)Dict.cxx $(subst .so,,$@)Dict.h
	@ cat VuotoLinkDef.h | sed s/Vuoto/$(subst .so,,$@)/g > $(subst .so,,$@)LinkDef.h	

	@ echo "$(HOSTNAME): GCC      $(subst .so,,$@)"	
	 $(COMPILER)  $(OPTIMIZE) $(INCLUDE) -c $(subst .so,,$@).cxx

	@ echo "$(HOSTNAME): ROOTCINT $(subst .so,,$@)"	
	@ $(ROOTCINT)  $(subst .so,,$@)Dict.cxx -c $(ROOTCINT_DEFINES) -p $(subst .so,,$@).h $(subst .so,,$@)LinkDef.h

	@ echo "$(HOSTNAME): GCC      $(subst .so,,$@)Dict"	
	@ $(COMPILER) $(OPTIMIZE) $(INCLUDE) -c $(subst .so,,$@)Dict.cxx

	@ echo "$(HOSTNAME): LD       $(subst .so,,$@).so"	
	@ $(COMPILER) -DNOROOT  $(OPTIMIZE) -ldl -shared  $(CAEN_VMELIB) -g $(subst .so,,$@).o $(subst .so,,$@)Dict.o -o $(subst .so,,$@).so 

	@ echo "$(HOSTNAME): ---> $(subst .so,,$@).so done."
	@ - rm -f $(subst .so,,$@)LinkDef.h $(subst .so,,$@)Dict.cxx $(subst .so,,$@)Dict.h\
		$(subst .so,,$@).cxx~  $(subst .so,,$@).h~ 



endef

##########################################################
##########################################################
##
## per aggiungere una nuova classe basta metterla in questo elenco qui :-))
##
SHAREDS=

##########################################################
############# CPU DETECTION: VME? ########################
##########################################################
ifneq ($(shell cat /proc/cpuinfo | grep MVME),)
	SHAREDS +=  FVmeControl.so FVmeTrigBox.so
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 2400),)
	COMPILER += -DMVME2400
	ROOTCINT_DEFINES += -DMVME2400
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 5100),)
	COMPILER += -DMVME5100
	ROOTCINT_DEFINES += -DMVME5100
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 6100),)
	COMPILER += -DMVME6100
	ROOTCINT_DEFINES += -DMVME6100
endif
ifneq ($(shell cat /proc/cpuinfo | grep MVME | grep 7100),)
	COMPILER += -DMVME7100
	ROOTCINT_DEFINES += -DMVME7100
endif
# solo per provare!!!
ifneq ($(shell ls /usr/lib | grep CAENVME),) 
#$(warning "WARNING: no CAENVME lib will be used NO CAEN_VME_BRIDGE!!")
$(warning "WARNING: Using CAENVME lib: defining  CAEN_VME_BRIDGE!!")
	COMPILER += -DCAEN_VME_BRIDGE
	ROOTCINT_DEFINES += -DCAEN_VME_BRIDGE
	SHAREDS +=  FVmeControl.so FVmeTrigBox.so
endif

##########################################################
##########################################################
export

all:    
	@ echo "using ROOT found in $(ROOTSYS) ..."
#	@ ${MAKE} depend 
	@ echo "checking for 64bit cpus..."
	@- rm -f cpu64bit.h
	@- $(ROOT-CONFIG) --arch | grep  linuxx8664gcc >/dev/null && echo "#define CPU64BIT" > cpu64bit.h
	@ touch  -t 0001010000 cpu64bit.h
	@ ${MAKE} $(SHAREDS)  libFTBOX.so 
	@ ${MAKE} Sdir.o
	- cp libFTBOX.so ../bin/libFTBOX.so
	- cp *.pcm ../bin/
# 	libCommon.o  
	#@ ${MAKE} $(LIBFIASCO).rootmap dbedit_dsp.out fair_dispatcher.out
#	-@ make docs
	#@echo "per generare la documentazione: make docs"
	#@ ls -l $(LIBFIASCO).so  dbedit_dsp.out fair_dispatcher.out
	#@ echo " ################### Done.####################"


#	- @echo ">>>>>>> Controllo versione: " $(shell cat   $(subst .so,.h,$(SHAREDS))  $(subst .so,.cxx,$(SHAREDS)) > /tmp/version.C ; md5sum /tmp/version.C  | sed s/" .*"//g; rm -f /tmp/version.C)
	#@echo

clean:
	- rm -f *~ $(SHAREDS) $(subst .so,.o,$(SHAREDS))  *Dict* libFTBOX.so 

libFTBOX.so: $(COMMONDEP) $(SHAREDS)
	- rm -v libFTBOX.so
	#@echo "$(HOSTNAME): LD       $(LIBFIASCO).so "
	@ $(COMPILER) -shared $(subst .so,.o,$(SHAREDS)) $(subst .so,Dict.o,$(SHAREDS)) $(CAEN_VMELIB) -o libFTBOX.so 
	#@ echo "$(HOSTNAME): ---> $(LIBFIASCO).so done."
	@ echo ""
	#@echo "Generazione di FIASCO.h..."
	#@ ./accapo.sh  $(subst .so,.h,$(SHAREDS)) | sed "s/^F/#include <F/g" | sed "s/^G/#include <G/g" | sed "s/^P/#include <P/g" | sed "s/\.h/\.h>/g" | grep -v libx | grep -v fftw.a > FIASCO.h
	#@ echo "" >> FIASCO.h
	#date > ZZZ_LastMakeDate.txt	
# 
# libCommon.o: $(COMMONDEP) $(SHAREDS)
# 	- rm -v libCommon.o
# 	#@echo "$(HOSTNAME): LD       $(LIBFIASCO).so "
# 	@ $(COMPILER) -c $(ROOTLIBS) $(ROOTFLAGS) $(CAEN_VMELIB) $(subst .so,.o,$(SHAREDS)) $(subst .so,Dict.o,$(SHAREDS)) -o libCommon.o 
# 	#@ echo "$(HOSTNAME): ---> $(LIBFIASCO).so done."
# 	@ echo ""
# 	#@echo "Generazione di FIASCO.h..."
# 	#@ ./accapo.sh  $(subst .so,.h,$(SHAREDS)) | sed "s/^F/#include <F/g" | sed "s/^G/#include <G/g" | sed "s/^P/#include <P/g" | sed "s/\.h/\.h>/g" | grep -v libx | grep -v fftw.a > FIASCO.h
# 	#@ echo "" >> FIASCO.h
# 	#date > ZZZ_LastMakeDate.txt	

## EVENTUALI COMPILAZIONI SPECIALI VANNO MESSE PRIMA DI QUESTA RULE!!!!
#%.so: NAME=$(subst .so,,$@)
#%.so: $(COMMONDEP) %.cxx %.h
#	$(COMPILA)
FVmeControl.so: $(COMMONDEP) FVmeControl.cxx FVmeControl.h vme_window.h
	$(COMPILA)
FVmeTrigBox.so: $(COMMONDEP) FVmeTrigBox.cxx FVmeTrigBox.h vme_window.h
	$(COMPILA)
Sdir.o : Sdir.h Sdir.cxx
	 $(COMPILER)  $(OPTIMIZE) $(INCLUDE) -c Sdir.cxx
