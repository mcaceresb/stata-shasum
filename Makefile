# ---------------------------------------------------------------------
# shasum flags

SPI = 3.0
CFLAGS = -Wall -O3 $(OSFLAGS)
EXTRA=

# build.py
# src/tests.do
# src/shasum.c

# ---------------------------------------------------------------------
# OS parsing

INCLUDE=
ifeq ($(OS),Windows_NT)
	LIBSSL = libssl.a
	LIBCRYPTO = libcrypto.a
	LIBPATH = ./lib/openssl/windows
	SSL = -L$(LIBPATH) -l:$(LIBSSL) -l:$(LIBCRYPTO)
	# SSL = -l:$(LIBSSL) -l:$(LIBCRYPTO)
	#
	OSFLAGS = -shared
	OUT = lib/plugin/shasum_windows.plugin
	# GCC = x86_64-w64-mingw32-gcc-5.4.0.exe
	GCC = x86_64-w64-mingw32-gcc.exe
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		LIBSSL = libssl.a
		LIBCRYPTO = libcrypto.a
		LIBPATH = ./lib/openssl/unix
		SSL = -L$(LIBPATH) -l:$(LIBSSL) -l:$(LIBCRYPTO)
		# SSL = -l:$(LIBSSL) -l:$(LIBCRYPTO)
		#
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
		OUT = lib/plugin/shasum_unix.plugin
	endif
	ifeq ($(UNAME_S),Darwin)
		LIBSSL = libssl.a
		LIBCRYPTO = libcrypto.a
		LIBPATH = ./lib/openssl/macosx
		SSL = $(LIBPATH)/$(LIBSSL) $(LIBPATH)/$(LIBCRYPTO)
		# SSL = -l:$(LIBSSL) -l:$(LIBCRYPTO)
		#
		OSFLAGS = -bundle -DSYSTEM=APPLEMAC
		OUT = lib/plugin/shasum_macosx.plugin
	endif
	GCC = gcc
endif

# ---------------------------------------------------------------------
# Rules

all: clean links shasum

links:
	rm -f  src/lib
	rm -f  src/spi
	ln -sf ../lib 	  src/lib
	ln -sf lib/spi-$(SPI) src/spi

shasum: src/shasum.c src/spi/stplugin.c
	mkdir -p ./build
	mkdir -p ./lib/plugin
	mkdir -p ./lib/openssl
	$(GCC) $(CFLAGS) $(EXTRA) $(INCLUDE) -o $(OUT)  src/spi/stplugin.c src/shasum.c $(SSL)
	cp lib/plugin/shasum*plugin build/

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTE)
