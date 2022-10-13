{smcl}
{* *! version 0.2.2 11Oct2022}{...}
{viewerdialog pyhash "dialog pyhash"}{...}
{vieweralsosee "[R] pyhash" "mansection R pyhash"}{...}
{viewerjumpto "Syntax" "pyhash##syntax"}{...}
{viewerjumpto "Description" "pyhash##description"}{...}
{viewerjumpto "Options" "pyhash##options"}{...}
{viewerjumpto "Examples" "pyhash##examples"}{...}
{title:Title}

{p2colset 5 15 19 2}{...}
{p2col :{cmd:pyhash} {hline 2}}Wrapper for Python's hashlib library{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

To hash a variable list or a list of files:

{p 8 15 2}
{cmd:pyhash}
{varlist}
{ifin}
{cmd:,}
gen({varlist}) hash({it:hashes})

{synoptset 18 tabbed}{...}
{marker pyhash_hash}{...}
{synopthdr}
{synoptline}
{marker pyhash_options}{...}
{syntab:Options}
{synopt :{opt hash:es(str)}} Hashes to use (any combination of hashes available in Python's hashlib are allowed)
{p_end}
{synopt :{opth gen:erate(str)}} Variables where to store the hashes.
{p_end}
{synopt :{opt replace}} Replace variables if they exist.
{p_end}

{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
Wrapper for Python's hashlib library functions.

{marker example}{...}
{title:Examples}

    {hline}
    Setup
{phang2}{cmd:. sysuse auto}

{pstd}Hash string variable.{p_end}
{phang2}{cmd:. pyhash make, gen(make_sha1) hash(sha1)}{p_end}
{phang2}{cmd:. pyhash make make, gen(makemake_sha1) hash(sha1)}{p_end}

{pstd}Hash a mix of string and numeric data. Note that we do not read
numbers as strings to any particular level of precision in order to hash
them. Rather, we hash the double-precision 64-bit representation of each
number.{p_end}
{phang2}{cmd:. pyhash make price, gen(makeprice_sha1) hash(sha1)}{p_end}

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

