shasum 
=======

Fast cryptographic hashing in Stata.

This package provides a C wrapper for the hash functions (checksums)
in the OpenSSL library, namely MD5, SHA1, SHA224, SHA256, SHA384, and
SHA512.

`version 0.1.1 07May2018`
<!-- Builds: Linux, OSX [![Travis Build Status](https://travis-ci.org/mcaceresb/stata-shasum.svg?branch=master)](https://travis-ci.org/mcaceresb/stata-shasum), -->
<!-- Windows (Cygwin) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/2bh1q9bulx3pl81p/branch/master?svg=true)](https://ci.appveyor.com/project/mcaceresb/stata-shasum) -->

Installation
------------

I only have access to Stata 13.1, so I impose that to be the minimum.
```stata
local github "https://raw.githubusercontent.com"
net install shasum, from(`github'/mcaceresb/stata-shasum/master/build/)
* adoupdate, update
* ado uninstall shasum
```

Usage
-----

```stata
sysuse auto, clear
shasum make, sha1(make_sha1)
shasum make if foreign, md5(make_md5) sha256(make_sha256)
help shasum
```

License
-------

shasum is [MIT-licensed](https://github.com/mcaceresb/stata-shasum/blob/master/LICENSE)
