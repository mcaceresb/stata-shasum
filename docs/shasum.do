* Setup
sysuse auto

* Hash string variable.
shasum make, sha1(make_sha1)
shasum make make, sha1(makemake_sha1)

* Hash a mix of string and numeric data. Note that we do not read
* numbers as strings to any particular level of precision in order to
* hash them. Rather, we hash the double-precision 64-bit representation
* of each number.
shasum make price, sha1(makeprice_sha1)

* Pad strings to be the same length. By default, we concatenate strings.
* So if you want to hash "a" and "hello", you can padd "a" with null
* characters to "a\0\0\0\0" so it is the same length as "hello" (well,
* not quite the same length, since the null character doesn't count for
* almost any other intents and purposes, but it does change the hash).
shasum make, sha1(make_sha1_pad) pad
shasum make, sha1(make_sha1_pad) pad

* You can also compute the hash of a list of files!
clear
set obs 1
findfile auto.dta
gen y = `"`r(fn)'"'
shasum y, sha1(shay)  filelist
l

* For files, you can pass the path in parts. If variable x contains
* "folder/" and variable y contains "file.ext", then you can do:
*
* shasum x y, sha1(shay) filelist path(/path/to/folder/)
*
* Note that shasum won't add path delimiters, so they must end in "/" or
* the file won't be found.
