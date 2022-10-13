*! version 0.2.2 11Oct2022 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Wrapper for OpenSSL's MD5, SHA1, SHA224, SHA256, SHA384, and SHA512

capture program drop shasum
program shasum, rclass
    version 14.2
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
        file(str)                 ///
        filelist                  ///
        path(str)                 ///
    ]

    local hash `md5'`sha1'`sha224'`sha256'`sha384'`sha512'
    local what `hash'`licenses'`file'

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

    if ( `"`file'"' != "" ) {
        local 0 `file'
        syntax anything(equalok), [MD5_ SHA1_ SHA224_ SHA256_ SHA384_ SHA512_]
        local hash_ `md5_'`sha1_'`sha224_'`sha256_'`sha384_'`sha512_'
        local file: copy local anything
        if ( `"`hash_'"' == `""' ) {
            disp as err "one of md5, sha1, sha224, sha256, sha384, or sha512 required to hash file."
            exit 198
        }
    }
    else if ( `"`filelist'"' != "" ) {
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
    else {
        confirm variable `varlist'
    }

    scalar __shasum_lpath = `:length local path'
    scalar __shasum_flist = (`"`filelist'"' != "")
    scalar __shasum_file  = (`"`file'"'     != "")
    scalar __shasum_lfile = `:length local file'

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

    if ( `"`file'"' == "" ) {
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
    }
    else if ( `"`file'"' != "" ) {
        forvalues i = 1 / 6 {
            local name:  word `i' of `hashname'
            local len:   word `i' of `hashlen'
            local len    `len'

            if ( "`debug'" != "" ) {
                disp "Parsing `name' (`len',`i'): ``name'_'"
            }

            if ( "``name'_'" != "" ) {
                local ++kout
                matrix __shasum_outlens  = nullmat(__shasum_outlens),  `len'
                matrix __shasum_shacodes = nullmat(__shasum_shacodes), `i'
            }
        }
        scalar __shasum_kvars_targets = `kout'
    }

    * Parse input
    * -----------

    local ifin `if' `in'
    if ( `"`if'"' != `""' ) {
        scalar __shasum_any_if = 1
    }
    else {
        scalar __shasum_any_if = 0
    }

    if ( `"`file'"' == "" ) {
        cap noi parse_types `varlist' `ifin'
        if ( _rc ) {
            local rc = _rc
            clean_all `rc'
            exit `rc'
        }
    }
    else if ( `"`file'"' != "" ) {
        scalar __shasum_kvars_sources = 0
        scalar __shasum_kvars_num     = 0
        scalar __shasum_kvars_str     = 0
        scalar __shasum_kvars_strL    = 0
        matrix __shasum_inlens        = .
        matrix __shasum_strL          = .
    }

    * Run the plugin
    * --------------

    if ( "`debug'" != "" ) {
        disp `"kout     = `kout'"'
        disp `"kin      = `=scalar(__shasum_kvars_sources)'"'
        disp `"any_if   = `=scalar(__shasum_any_if)'"'
        disp `""'
        disp `"filelist = `=scalar(__shasum_flist)'"'
        disp `""'
        disp `"file     = `=scalar(__shasum_file)', `=scalar(__shasum_lfile)'"'
        disp `"           `file'"'
        disp `"path     = `=scalar(__shasum_lpath)'"'
        disp `"           `path'"'
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

    if ( `"`file'"' != "" ) {
        if (`"`r_md5'"'    != "") disp `"`r_md5'"'
        if (`"`r_sha1'"'   != "") disp `"`r_sha1'"'
        if (`"`r_sha224'"' != "") disp `"`r_sha224'"'
        if (`"`r_sha256'"' != "") disp `"`r_sha256'"'
        if (`"`r_sha384'"' != "") disp `"`r_sha384'"'
        if (`"`r_sha512'"' != "") disp `"`r_sha512'"'
        return local md5    = `"`r_md5'"'
        return local sha1   = `"`r_sha1'"'
        return local sha224 = `"`r_sha224'"'
        return local sha256 = `"`r_sha256'"'
        return local sha384 = `"`r_sha384'"'
        return local sha512 = `"`r_sha512'"'
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
    cap matrix drop __shasum_strL

    * Check how many of each variable type we have
    * --------------------------------------------

    local genstrl 0
    foreach invar of varlist `varlist' {
        if regexm("`:type `invar''", "str([1-9][0-9]*|L)") {
            if ( regexs(1) == "L" ) {
                local genstrl 1
            }
        }
    }
    tempvar strlen
    if ( `genstrl' ) qui gen long `strlen' = .

    local kvars = 0
    local knum  = 0
    local kstr  = 0
    local kstrL = 0

    local varnum  ""
    local varstr  ""
    local varstrL ""

    foreach invar of varlist `varlist' {
        local ++kvars
        if regexm("`:type `invar''", "str([1-9][0-9]*|L)") {
            local ++kstr
            local varstr `varstr' `invar'
            if ( regexs(1) == "L" ) {
                local ++kstrL
                local varstrL `varstrL' `invar'
                qui replace `strlen' = length(`invar')
                qui sum `strlen', meanonly
                matrix __shasum_inlens = nullmat(__shasum_inlens), `r(max)' + 1
                matrix __shasum_strL   = nullmat(__shasum_strL),   1
            }
            else {
                matrix __shasum_inlens = nullmat(__shasum_inlens), `:di regexs(1)'
                matrix __shasum_strL   = nullmat(__shasum_strL),   0
            }
        }
        else if inlist("`:type `invar''", "byte", "int", "long", "float", "double") {
            local ++knum
            local varnum `varnum' `invar'
            matrix __shasum_inlens = nullmat(__shasum_inlens), 0
            matrix __shasum_strL   = nullmat(__shasum_strL),   0
        }
        else {
            di as err "variable `invar' has unknown type '`:type `invar'''"
            exit 198
        }
    }

    if ( `kstrL' & `c(stata_version)' < 14.1 ) {
        disp as err "strL variables not supported in this version of Stata"
        exit 17002
    }

    cap assert `kvars' == `:list sizeof varlist'
    if ( _rc ) {
        di as err "Error parsing syntax call; variable list was:" ///
            _n(1) "`anything'"
        exit 198
    }

    * Parse which hashing strategy to use
    * -----------------------------------

    scalar __shasum_kvars_sources = `kvars'
    scalar __shasum_kvars_num     = `knum'
    scalar __shasum_kvars_str     = `kstr'
    scalar __shasum_kvars_strL    = `kstrL'

    * Return hash info
    * ----------------

    return local varlist = "`varlist'"
    return local varnum  = "`varnum'"
    return local varstr  = "`varstr'"
    return local varstrL = "`varstrL'"
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
    cap scalar drop __shasum_kvars_strL
    cap scalar drop __shasum_debug
    cap scalar drop __shasum_lpath
    cap scalar drop __shasum_flist
    cap scalar drop __shasum_file
    cap scalar drop __shasum_lfile

    cap matrix drop __shasum_inlens
    cap matrix drop __shasum_strL
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

cap program drop shasum_plugin
program shasum_plugin, plugin using("shasum_`c_os_'.plugin")
