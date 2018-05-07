{smcl}
{* *! version 0.1.1 07May2018}{...}
{viewerdialog shasum "dialog shasum"}{...}
{vieweralsosee "[R] shasum" "mansection R shasum"}{...}
{viewerjumpto "Syntax" "shasum##syntax"}{...}
{viewerjumpto "Description" "shasum##description"}{...}
{viewerjumpto "Options" "shasum##options"}{...}
{viewerjumpto "Examples" "shasum##examples"}{...}
{title:Title}

{p2colset 5 15 19 2}{...}
{p2col :{cmd:shasum} {hline 2}}Wrapper for various cryptographic hashes from OpenSSL{p_end}
{p2colreset}{...}

{pstd}
{it:Note for Windows users}: It may be necessary to run
{opt shasum, dependencies} at the start of your Stata session.

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:shasum}
{varlist}
{ifin}
{cmd:,}
[{it:{help shasum##shasum_hash:shasum_hash}}
({newvar})
{it:{help shasum##shasum_options:shasum_options}}]

{synoptset 18 tabbed}{...}
{marker shasum_hash}{...}
{marker shasum_options}{...}
{synopthdr}
{synoptline}
{syntab:Hash}
{synopt :{opth md5(newvar)}}    Store 128-bit MD5 hash of {it:varlist} in {it:md5} (32 hex characters)
{p_end}
{synopt :{opth sha1(newvar)}}   Store 160-bit SHA1 hash of {it:varlist} in {it:sha1} (40 hex characters)
{p_end}
{synopt :{opth sha224(newvar)}} Store 224-bit SHA224 hash of {it:varlist} in {it:sha224} (56 hex characters)
{p_end}
{synopt :{opth sha256(newvar)}} Store 256-bit SHA256 hash of {it:varlist} in {it:sha256} (64 hex characters)
{p_end}
{synopt :{opth sha384(newvar)}} Store 384-bit SHA384 hash of {it:varlist} in {it:sha384} (96 hex characters)
{p_end}
{synopt :{opth sha512(newvar)}} Store 512-bit SHA512 hash of {it:varlist} in {it:sha512} (128 hex characters)
{p_end}

{syntab:Extras}
{synopt :{opt pad}} Pad strings with null characters.
{p_end}
{synopt :{opt dependencies}} Download windows DLLs to working directory.
{p_end}
{synopt :{opt licenses}} Print open source licenses.
{p_end}

{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
This package provides a wrapper for the hash functions (checksums)
in the OpenSSL library, namely MD5, SHA1, SHA224, SHA256, SHA384, and
SHA512 using C plugins.

{marker example}{...}
{title:Examples}

    {hline}
    Setup
{phang2}{cmd:. sysuse auto}

{pstd}Hash string variable.{p_end}
{phang2}{cmd:. shasum make, sha1(make_sha1)}{p_end}
{phang2}{cmd:. shasum make make, sha1(makemake_sha1)}{p_end}

{pstd}Hash a mix of string and numeric data. Note that we do not read
numbers as strings to any particular level of precision in order to hash
them. Rather, we hash the double-precision 64-bit representation of each
number.{p_end}
{phang2}{cmd:. shasum make price, sha1(makeprice_sha1)}{p_end}

{pstd}Pad strings to be the same length. By default, we concatenate
strings. So if you want to hash "a" and "hello", you can padd "a" with
null characters to "a\0\0\0\0" so it is the same length as "hello". {p_end}
{phang2}{cmd:. shasum make, sha1(make_sha1_pad) pad}{p_end}

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{pstd}
I am also the author of the {manhelp gtools R:gtools} project at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{title:Also see}

{p 4 13 2}
{help gtools} (if installed)

