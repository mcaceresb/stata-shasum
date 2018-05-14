*! version 0.1.4 13May2018 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Wrapper for OpenSSL's MD5, SHA1, SHA224, SHA256, SHA384, and SHA512

capture program drop shasum
program shasum
    syntax [varlist] [if] [in], [ ///
        LICENSEs                  ///
                                  ///
        md5(str)                  /// 128-bit hash (32 hex characters)
        sha1(str)                 /// 160-bit hash (40 hex characters)
        sha224(str)               /// 224-bit hash (56 hex characters)
        sha256(str)               /// 256-bit hash (64 hex characters)
        sha384(str)               /// 384-bit hash (96 hex characters)
        sha512(str)               /// 512-bit hash (128 hex characters)
                                  ///
        pad                       ///
        debug                     ///
        FILElist                  ///
        path(str)                 ///
    ]

    local hash `md5'`sha1'`sha224'`sha256'`sha384'`sha512'
    local what `hash'`licenses'

    if ( `"`what'"' == `""' ) {
        disp as err "one of md5(), sha1(), sha224(), sha256(), sha384(), or sha512() required."
        exit 198
    }

    * Licenses
    * --------

    if ( "`licenses'" != "" ) {
        disp `"shasum is {browse "https://github.com/mcaceresb/stata-shasum/blob/master/LICENSE":MIT-licensed }"'
        disp ""
        disp `"The GNU C library is GPL-licensed. See the {browse "http://www.gnu.org/licenses/":GNU lesser GPL for more details}."'
        disp ""
        disp `"The OpenSSL library and toolkit are under the {browse "https://www.openssl.org/source/license.html":OpenSSL license}."'
        if ( `"`hash'"' == `""' ) {
            exit 0
        }
    }

    if ( `"`filelist'"' == "" ) {
        confirm variable `varlist'
    }
    else {
        cap noi confirm str variable `varlist'
        if ( _rc ) {
            disp as err "numeric variables not allowed with option {opt filelist}"
            exit _rc
        }

        if ( `"`pad'"' != "" ) {
            disp as err "option {opt pad} not allowed with {opt filelist}"
            exit _rc
        }
    }
    scalar __shasum_lpath = `:length local path'
    scalar __shasum_flist = `"`filelist'"' != ""

    * Parse requested output
    * ----------------------

    local hashname md5 sha1 sha224 sha256 sha384 sha512
    local hashlen  32  40   56     64     96     128

    qui mata: __shasum_addvars  = J(1, 0, "")
    qui mata: __shasum_addtypes = J(1, 0, "")

    cap matrix drop __shasum_outlens
    cap matrix drop __shasum_shacodes
    local outvars
    local kout = 0
    forvalues i = 1 / 6 {
        local name:  word `i' of `hashname'
        local len:   word `i' of `hashlen'
        local len    `len'
        local `name' ``name''

        if ( "`debug'" != "" ) {
            disp "Parsing `name' (`len',`i'): ``name''"
        }

        if ( "``name''" != "" ) {
            cap noi confirm new variable ``name''
            if ( _rc ) {
                local rc = _rc
                clean_all `rc'
                exit `rc'
            }
            local outvars `outvars' ``name''
            local ++kout
            qui mata: __shasum_addvars  = __shasum_addvars,  "``name''"
            qui mata: __shasum_addtypes = __shasum_addtypes, "str`len'"
            matrix __shasum_outlens  = nullmat(__shasum_outlens),  `len'
            matrix __shasum_shacodes = nullmat(__shasum_shacodes), `i'
        }
    }
    scalar __shasum_kvars_targets = `kout'

    * Parse input
    * -----------

    local ifin `if' `in'
    if ( `"`if'"' != `""' ) {
        scalar __shasum_any_if = 1
    }
    else {
        scalar __shasum_any_if = 0
    }

    cap noi parse_types `varlist' `ifin'
    if ( _rc ) {
        local rc = _rc
        clean_all `rc'
        exit `rc'
    }

    * Run the plugin
    * --------------

    if ( "`debug'" != "" ) {
        disp "kout   = `kout'"
        disp "kin    = `=scalar(__shasum_kvars_sources)'"
        disp "any_if = `=scalar(__shasum_any_if)'"
    }
    scalar __shasum_debug  = ( "`debug'" != "" )
    scalar __shasum_concat = ( "`pad'"   == "" )

    qui mata: st_addvar(__shasum_addtypes, __shasum_addvars)
    cap noi plugin call shasum_plugin `varlist' `outvars' `ifin'
    if ( _rc ) {
        local rc = _rc
        clean_all `rc'
        exit `rc'
    }

    * Clean up
    * --------

    clean_all 0
    exit 0
end

***********************************************************************
*                        Parse variable types                         *
***********************************************************************

capture program drop parse_types
program parse_types, rclass
    syntax varlist [if] [in]

    cap matrix drop __shasum_inlens

    * Check how many of each variable type we have
    * --------------------------------------------

    local knum  = 0
    local kstr  = 0
    local kvars = 0

    local varnum  ""
    local varstr  ""
    local varstrL ""

    foreach invar of varlist `varlist' {
        local ++kvars
        if inlist("`:type `invar''", "byte", "int", "long", "float", "double") {
            local ++knum
            local varnum `varnum' `invar'
            matrix __shasum_inlens = nullmat(__shasum_inlens), 0
        }
        else {
            local ++kstr
            local varstr `varstr' `invar'
            if regexm("`:type `invar''", "str([1-9][0-9]*|L)") {
                if (regexs(1) == "L") {
                    local varstrL `varstrL' `invar'
                    matrix __shasum_inlens = nullmat(__shasum_inlens), .
                }
                else {
                    matrix __shasum_inlens = nullmat(__shasum_inlens), `:di regexs(1)'
                }
            }
            else {
                di as err "variable `invar' has unknown type '`:type `invar'''"
                exit 198
            }
        }
    }

    cap assert `kvars' == `:list sizeof varlist'
    if ( _rc ) {
        di as err "Error parsing syntax call; variable list was:" ///
            _n(1) "`anything'"
        exit 198
    }

    if ( "`varstrL'" != "" ) {
        disp as err _n(1) "shasum 0.1.x does not support strL variables. If your strL variables"    ///
                    _n(1) "are string-only, try"                                                    ///
                    _n(2) "    {stata compress `varstrL'}"                                          ///
                    _n(2) "If this does not work or if you have binary data, then you will have to" ///
                    _n(1) "wait for the next release of shasum (0.2)."                              ///
                    _n(2) "This limitation comes from the Stata Plugin Interface (SPI) 2.0"         ///
                    _n(1) "that was used to write shasum. 3.0 (Stata 14 and above only) added"      ///
                    _n(1) "support for strL variables. shasum will add strL support in its next"    ///
                    _n(1) "relase (0.2)."
        exit 17003
    }

    * Parse which hashing strategy to use
    * -----------------------------------

    scalar __shasum_kvars_sources = `kvars'
    scalar __shasum_kvars_num     = `knum'
    scalar __shasum_kvars_str     = `kstr'

    * Return hash info
    * ----------------

    return local varlist = "`varlist'"
    return local varnum  = "`varnum'"
    return local varstr  = "`varstr'"
end

***********************************************************************
*                            Misc helpers                             *
***********************************************************************

capture program drop clean_all
program clean_all
    args rc
    if ( "`rc'" == "" ) {
        local rc = 0
    }

    if ( `rc' ) {
        cap mata: st_dropvar(__shasum_addvars)
    }

    cap scalar drop __shasum_kvars_targets
    cap scalar drop __shasum_kvars_sources
    cap scalar drop __shasum_kvars_num
    cap scalar drop __shasum_kvars_str
    cap scalar drop __shasum_debug
    cap scalar drop __shasum_lpath
    cap scalar drop __shasum_flist

    cap matrix drop __shasum_inlens
    cap matrix drop __shasum_outlens
    qui mata: mata drop __shasum_addvars
    qui mata: mata drop __shasum_addtypes

    cap timer off   99
    cap timer clear 99

    cap timer off   98
    cap timer clear 98
end

***********************************************************************
*                             Load plugin                             *
***********************************************************************

if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) local c_os_ macosx
else local c_os_: di lower("`c(os)'")

* cap program drop env_set
* program env_set, plugin using("env_set_`c_os_'.plugin")

cap program drop shasum_plugin
program shasum_plugin, plugin using("shasum_`c_os_'.plugin")
