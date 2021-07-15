COMMONDIR = Common
PROGDIRS = Programmer Oscilloscope GUI
FTBOX_STORAGE = $(HOME)/FTBOX_Saves




all:
	#- echo $(FTBOX_STORAGE)
	#@ echo "#define FTBOX_DIR \"$(FTBOX_STORAGE)\"" > Common/Sdir.h 
	#- mkdir $(FTBOX_STORAGE)
	- mkdir bin
	- rm -r bin/*
	#make clean
	$(MAKE) -C $(COMMONDIR) all
	for dir in $(PROGDIRS); do \
		$(MAKE) -C $$dir all; \
	done
# 	$(MAKE) -C $(COMMONDIR) clean
	



install:
	- cp bin/*.so /usr/local/lib/
	- cp bin/*.pcm /usr/local/lib/
	- cp bin/ftbox* /usr/local/bin/
	
	
clean:
	$(MAKE) -C $(COMMONDIR) clean
	for dir in $(PROGDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
