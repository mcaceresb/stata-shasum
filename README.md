shasum
======

Fast cryptographic hashing in Stata.

This package provides a C wrapper for the hash functions (checksums)
in the OpenSSL library, namely MD5, SHA1, SHA224, SHA256, SHA384, and
SHA512. It also includes a short wrapper for Python's hashlib functions
(Stata 16+ only; this is specially convenient if you have difficulty
compiling the plugin).

`version 0.2.2 11Oct2022`

Installation
------------

Pre-compiled binaries are provided, but it is possible you will have
to compile the plugin yourself (in particular in OSX). If the function
fails, see the [compiling section below](#compiling).

```stata
local github "https://raw.githubusercontent.com"
net install shasum, from(`github'/mcaceresb/stata-shasum/master/build)
* adoupdate, update
* ado uninstall shasum
```

Usage
-----

```stata
sysuse auto

* Hash string variable.
shasum make, sha1(make_sha1)
shasum make make, sha1(makemake_sha1)

* Hash a mix of string and numeric data. Note that we do not read
* numbers as strings to any particular level of precision in order to
* hash them. Rather, we hash the double-precision 64-bit representation
* of each number.
shasum make price, sha1(makeprice_sha1)

* Use Python's hashlib
pyhash make make,  hashes(sha1) gen(makemake_pysha1)
pyhash make price, hashes(sha1) gen(makeprice_pysha1)
assert makemake_pysha1  == makemake_sha1 
assert makeprice_pysha1 == makeprice_sha1

* Pad strings to be the same length. By default, we concatenate strings.
* So if you want to hash "a" and "hello", you can padd "a" with null
* characters to "a\0\0\0\0" so it is the same length as "hello".
shasum make, sha1(make_sha1_pad) pad

* You can also hash a file
findfile auto.dta
shasum, file(`r(fn)', sha1)
return list
local sha1 = `"`r(sha1)'"'

* or a list of files
clear
set obs 1
findfile auto.dta
gen y = `"`r(fn)'"'
shasum y, sha1(shay) filelist
assert `"`=shay[1]'"' == `"`sha1'"'
l

help shasum
```

For files, you can pass the path in parts. If variable x contains
"folder/" and variable y contains "file.ext", then you can do:
```stata
shasum x y, sha1(shay) filelist path(/path/to/folder/)
```

Note that shasum won't add path delimiters, so they must end in "/" or
the file won't be found.

Compiling
---------

To compile, you will need

- The GNU compiler collection (gcc)
- git
- OpenSSL
- Cygwin (on Windows) with gcc, make, x86_64-w64-mingw32-gcc-5.4.0.exe, and OpenSSL (Cygwin is pretty massive by default; I would install only those packages).

From OpenSSL, you need, in particular, `libssl.a` and `libcrypto.a`
as well as the headers `md5.h` and `sha.h` If you have all this in
your path, run

```sh
git clone https://github.com/mcaceresb/stata-shasum
cd stata-shasum
make SSL="-lssl -lcrypto"
```

This only works if you have OpenSSL installed. If you don't (or if you
get any errors) then you can compile a static version of OpenSSL. This
is fairly straightforward on Linux and OSX by following the instructions
[here](https://wiki.openssl.org/index.php/Compilation_and_Installation). For OSX, for example,

```sh
git clone git://git.openssl.org/openssl.git
cd openssl
git checkout OpenSSL_1_1_1-stable
./Configure darwin64-x86_64-cc
export KERNEL_BITS=64
./config
make
```

Then you can run
```sh
cd ../stata-shasum
make LIBPATH=../openssl INCLUDE=-I../openssl/include
```

In either case, once you have compiled the plugin you need
to install (or re-install) the  package. From Stata (replacing
`` `c(pwd)' `` with the path to where you cloned the repo):
```stata
cap noi ado uninstall shasum
cap noi net uninstall shasum
net install shasum, from(`c(pwd)'/stata-shasum/build) replace
```

Notes
-----

- I compile version 1.1.1 of OpenSSL; this plugin may not be
  compatible with the latest version 3.0; see [issue #2](https://github.com/mcaceresb/stata-shasum/issues/2) for more.

- If you have an older stata version (14.0 or earlier) then
  compile the Stata plugin using `make SPI=2.0`.

License
-------

stata-shasum is [MIT-licensed](https://github.com/mcaceresb/stata-shasum/blob/master/LICENSE)
