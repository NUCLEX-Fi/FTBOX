/*
  $Header: /home/CVS/luigi/FClasses/gcc3_fixes.h,v 1.5 2017-04-09 15:38:42 garfield Exp $
  $Log: gcc3_fixes.h,v $
  Revision 1.5  2017-04-09 15:38:42  garfield
  New version of FClasses compiling both with root5 (5.32) and root6
  (6.08). The Makefile now checks for ROOT version. We had to add again
  libFIASCO to library lists in libFIASCO.*.rootmap in order to correctly
  load the libraries (e.g. when creating a FDigitalFWizard object, some
  libraries were not autoloaded.

  Revision 1.4  2008-07-23 09:14:52  bardelli
  Ulteriori correzioni per le CPU a 64 bit

  Revision 1.3  2007/03/21 11:15:20  bardelli
  vari ritocchi per funzionare con ROOT 5.15

  Revision 1.2  2006/05/05 13:10:26  bardelli
  Aggiunto Header e Log in testa a tutti i files

*/

/*
  Ho cercato di raccogliere qui tutte le correzioni da fare
  per passare da gcc 2.9x a gcc 3.xx.

  E' necessario togliere anche i valori di default:
   con xemacs regexp replace:
   =[^,\)\\n]+,       ====>>       ,
   =[^,\)\(\\n=]+[\)] ====>>       )
  auguri...

  

*/

#ifndef _LUIGI_GCC3_FIXES_
#define _LUIGI_GCC3_FIXES_

/* remove all inlines! Lo faccio fare al compilatore... */
#define INLINE

/*--- gcc 3.xx is different from 2.9x GRRRRRRRR ---------------*/
#define GCC_VERSION (__GNUC__ * 10000 \
                     + __GNUC_MINOR__ * 100 \
                       + __GNUC_PATCHLEVEL__)
#if GCC_VERSION > 30000
    using namespace std;
    #include <iostream>
    #include <fstream>  
#else
    #include <iostream.h>
    #include <fstream.h>  
#endif

#undef GCC_VERSION
/*-------------------------------------------------------------*/


#endif

#include <math.h>
#include "cpu64bit.h"
