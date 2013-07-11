Building QtBinPatcher for Windows.
MinGW (x86 and x86_64)
	mingw32-make -f Makefile.win.mingw
MSYS (with g++, x86 and x86_64)
    make -f Makefile.win.msys
MSVC (2008, 2010, 2012, x86 and x86_64)
	nmake -f Makefile.win.msvc
	
Building QtBinPatcher for Linux.
GCC (x86 and x86_64)
    make -f Makefile.linux.gcc
