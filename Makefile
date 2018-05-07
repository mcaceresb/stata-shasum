# ---------------------------------------------------------------------
# OS parsing

ifeq ($(OS),Windows_NT)
	LIBSSL = libssl.a
	LIBCRYPTO = libcrypto.a
	LIBPATH = ./lib/openssl/
	SSL = -L$(LIBPATH) -l:$(LIBSSL) -l:$(LIBCRYPTO)
	# SSL = -l:$(LIBSSL) -l:$(LIBCRYPTO)
	#
	OSFLAGS = -shared
	OUT = build/shasum_windows.plugin
	OUTE = build/env_set_windows.plugin
	# GCC = x86_64-w64-mingw32-gcc-5.4.0.exe
	GCC = x86_64-w64-mingw32-gcc.exe
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		LIBSSL = libssl.a
		LIBCRYPTO = libcrypto.a
		LIBPATH = ./lib/openssl/
		SSL = -L$(LIBPATH) -l:$(LIBSSL) -l:$(LIBCRYPTO)
		# SSL = -l:$(LIBSSL) -l:$(LIBCRYPTO)
		#
		OSFLAGS = -shared -fPIC -DSYSTEM=OPUNIX
		OUT = build/shasum_unix.plugin
		OUTE = build/env_set_unix.plugin
	endif
	ifeq ($(UNAME_S),Darwin)
		LIBSSL = libssl.so
		LIBCRYPTO = libcrypto.so
		LIBPATH = ./lib/openssl/
		SSL = -L./$(LIBPATH) -l:$(LIBSSL) -l:$(LIBCRYPTO)
		# SSL = -l:$(LIBSSL) -l:$(LIBCRYPTO)
		#
		OSFLAGS = -bundle -DSYSTEM=APPLEMAC
		OUT = build/shasum_macosx$(LEGACY).plugin
		OUTE = build/env_set_macosx$(LEGACY).plugin
	endif
	GCC = gcc
endif

# ---------------------------------------------------------------------
# shasum flags

SPI = 2.0
CFLAGS = -Wall -O3 $(OSFLAGS)

all: clean links shasum

# ---------------------------------------------------------------------
# Rules

links:
	rm -f  src/lib
	rm -f  src/spi
	ln -sf ../lib 	  src/lib
	ln -sf lib/spi-$(SPI) src/spi

shasum: src/shasum.c src/spi/stplugin.c
	mkdir -p ./build
	mkdir -p ./lib/plugin
	mkdir -p ./lib/openssl
	$(GCC) $(CFLAGS) -o $(OUT)  src/spi/stplugin.c src/shasum.c $(SSL)
	$(GCC) $(CFLAGS) -o $(OUTE) src/spi/stplugin.c src/env_set.c
	cp build/*plugin lib/plugin/

.PHONY: clean
clean:
	rm -f $(OUT) $(OUTE)
