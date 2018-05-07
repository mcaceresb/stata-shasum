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
* characters to "a\0\0\0\0" so it is the same length as "hello".
shasum make, sha1(make_sha1_pad) pad
