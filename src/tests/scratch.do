capture program drop get_dll
program get_dll
    local cwd         `c(pwd)'
    local github      https://raw.githubusercontent.com/mcaceresb/stata-shasum/master
    local github_url  `github'/lib/windows

    local libssl_dll    libssl.dll
    local libcrypto_dll libcrypto.dll

    * Download libssl
    * ---------------

    cap confirm file `libssl_dll'
    if ( _rc ) {
        local download `github_url'/`libssl_dll'
    }
    else {
        local download `c(pwd)'/`libssl_dll'
    }

    cap mkdir `"`c(sysdir_plus)'l/"'
    cap cd    `"`c(sysdir_plus)'l/"'
    if ( _rc ) {
        local url `github_url'/`libssl_dll'
        di as err `"Could not find directory '`c(sysdir_plus)'l/'"'
        di as err `"Please download {browse "`url'":`libssl_dll'} to your shasum installation."'
        cd `"`cwd'"'
        exit _rc
    }

    cap confirm file `libssl_dll'
    if ( _rc == 0 ) {
        di as txt "`libssl_dll' already installed."
        cd `"`cwd'"'
        exit 0
    }

    cap erase `libssl_dll'
    cap copy `"`download'"' `libssl_dll'
    if ( _rc ) {
        di as err "Unable to download `libssl_dll' from `download'."
        cd `"`cwd'"'
        exit _rc
    }

    cap confirm file `libssl_dll'
    if ( _rc ) {
        di as err "`libssl_dll' could not be installed. -shasum- programs may fail on Windows."
        cd `"`cwd'"'
        exit _rc
    }

    * Download libcrypto
    * ------------------

    cap confirm file `libcrypto_dll'
    if ( _rc ) {
        local download `github_url'/`libcrypto_dll'
    }
    else {
        local download `c(pwd)'/`libcrypto_dll'
    }

    cap mkdir `"`c(sysdir_plus)'l/"'
    cap cd    `"`c(sysdir_plus)'l/"'
    if ( _rc ) {
        local url `github_url'/`libcrypto_dll'
        di as err `"Could not find directory '`c(sysdir_plus)'l/'"'
        di as err `"Please download {browse "`url'":`libcrypto_dll'} to your shasum installation."'
        cd `"`cwd'"'
        exit _rc
    }

    cap confirm file `libcrypto_dll'
    if ( _rc == 0 ) {
        di as txt "`libcrypto_dll' already installed."
        cd `"`cwd'"'
        exit 0
    }

    cap erase `libcrypto_dll'
    cap copy `"`download'"' `libcrypto_dll'
 hash   if ( _rc ) {
        di as err "Unable to download `libcrypto_dll' from `download'."
        cd `"`cwd'"'
        exit _rc
    }

    cap confirm file `libcrypto_dll'
    if ( _rc ) {
        di as err "`libcrypto_dll' could not be installed. -shasum- programs may fail on Windows."
        cd `"`cwd'"'
        exit _rc
    }

    * Success
    * -------

    di as txt "Successfully downloaded `libssl_dll' and `libcrypto_dll'."
    cd `"`cwd'"'
    exit 0
end

* Windows hack
* ------------

* if ( "`c_os_'" == "windows" ) {
*
*     * Look for libssl
*     * ---------------
*
*     cap confirm file libssl.dll
*     if ( _rc ) {
*
*         cap findfile libssl.dll
*         if ( _rc ) {
*             local rc = _rc
*             local url https://raw.githubusercontent.com/mcaceresb/stata-shasum
*             local url `url'/master/lib/windows/libssl.dll
*             di as err `"shasum: libssl.dll not found."' _n(1)     ///
*                       `"shasum: download {browse "`url'":here}"' ///
*                       `" or run {opt shasum, dependencies}"'
*             exit `rc'
*         }
*
*         mata: __shasum_hashpath = ""
*         mata: __shasum_dll      = ""
*         mata: pathsplit(`"`r(fn)'"', __shasum_hashpath, __shasum_dll)
*         mata: st_local("__shasum_hashpath", __shasum_hashpath)
*         mata: mata drop __shasum_hashpath
*         mata: mata drop __shasum_dll
*         local path: env PATH
*         if inlist(substr(`"`path'"', length(`"`path'"'), 1), ";") {
*             mata: st_local("path", substr(`"`path'"', 1, `:length local path' - 1))
*         }
*
*         local __shasum_hashpath: subinstr local __shasum_hashpath "/" "\", all
*         local newpath `"`path';`__shasum_hashpath'"'
*         local truncate 2048
*         if ( `:length local newpath' > `truncate' ) {
*             local loops = ceil(`:length local newpath' / `truncate')
*             mata: __shasum_pathpieces = J(1, `loops', "")
*             mata: __shasum_pathcall   = ""
*             mata: for(k = 1; k <= `loops'; k++) __shasum_pathpieces[k] = substr(st_local("newpath"), 1 + (k - 1) * `truncate', `truncate')
*             mata: for(k = 1; k <= `loops'; k++) __shasum_pathcall = __shasum_pathcall + " `" + `"""' + __shasum_pathpieces[k] + `"""' + "' "
*             mata: st_local("pathcall", __shasum_pathcall)
*             mata: mata drop __shasum_pathcall __shasum_pathpieces
*             cap plugin call env_set, PATH `pathcall'
*         }
*         else {
*             cap plugin call env_set, PATH `"`path';`__shasum_hashpath'"'
*         }
*
*         if ( _rc ) {
*             cap confirm file libssl.dll
*             if ( _rc ) {
*                 cap plugin call env_set, PATH `"`__shasum_hashpath'"'
*                 if ( _rc ) {
*                     local rc = _rc
*                     di as err `"shasum: Unable to add '`__shasum_hashpath''"' ///
*                               `"to system PATH."'                             ///
*                         _n(1) `"shasum: download {browse "`url'":here}"'      ///
*                               `" or run {opt shasum, dependencies}"'
*                     exit `rc'
*                 }
*             }
*         }
*     }
*
*     * Look for libcrypto
*     * ------------------
*
*     cap confirm file libcrypto.dll
*     if ( _rc ) {
*
*         cap findfile libcrypto.dll
*         if ( _rc ) {
*             local rc = _rc
*             local url https://raw.githubusercontent.com/mcaceresb/stata-shasum
*             local url `url'/master/lib/windows/libcrypto.dll
*             di as err `"shasum: libcrypto.dll not found."' _n(1) ///
*                       `"shasum: download {browse "`url'":here}"' ///
*                       `" or run {opt shasum, dependencies}"'
*             exit `rc'
*         }
*
*         mata: __shasum_hashpath = ""
*         mata: __shasum_dll      = ""
*         mata: pathsplit(`"`r(fn)'"', __shasum_hashpath, __shasum_dll)
*         mata: st_local("__shasum_hashpath", __shasum_hashpath)
*         mata: mata drop __shasum_hashpath
*         mata: mata drop __shasum_dll
*         local path: env PATH
*         if inlist(substr(`"`path'"', length(`"`path'"'), 1), ";") {
*             mata: st_local("path", substr(`"`path'"', 1, `:length local path' - 1))
*         }
*
*         local __shasum_hashpath: subinstr local __shasum_hashpath "/" "\", all
*         local newpath `"`path';`__shasum_hashpath'"'
*         local truncate 2048
*         if ( `:length local newpath' > `truncate' ) {
*             local loops = ceil(`:length local newpath' / `truncate')
*             mata: __shasum_pathpieces = J(1, `loops', "")
*             mata: __shasum_pathcall   = ""
*             mata: for(k = 1; k <= `loops'; k++) __shasum_pathpieces[k] = substr(st_local("newpath"), 1 + (k - 1) * `truncate', `truncate')
*             mata: for(k = 1; k <= `loops'; k++) __shasum_pathcall = __shasum_pathcall + " `" + `"""' + __shasum_pathpieces[k] + `"""' + "' "
*             mata: st_local("pathcall", __shasum_pathcall)
*             mata: mata drop __shasum_pathcall __shasum_pathpieces
*             cap plugin call env_set, PATH `pathcall'
*         }
*         else {
*             cap plugin call env_set, PATH `"`path';`__shasum_hashpath'"'
*         }
*
*         if ( _rc ) {
*             cap confirm file libcrypto.dll
*             if ( _rc ) {
*                 cap plugin call env_set, PATH `"`__shasum_hashpath'"'
*                 if ( _rc ) {
*                     local rc = _rc
*                     di as err `"shasum: Unable to add '`__shasum_hashpath''"' ///
*                               `"to system PATH."'                             ///
*                         _n(1) `"shasum: download {browse "`url'":here}"'      ///
*                               `" or run {opt shasum, dependencies}"'
*                     exit `rc'
*                 }
*             }
*         }
*     }
* }

* Plugin vs python
* ----------------

sysuse auto, clear
gen byte test = mod(_n, 2)
pyhash price make test headroom, gen(pymd5 py256) hash(md5 sha256)
shasum price make test headroom, md5(statamd5) sha256(stata256)
assert pymd5 == statamd5
assert py256 == stata256

pyhash price make headroom if test, gen(pymd5 py1 py256) hash(md5 sha1 sha256) replace
drop stata*
shasum price make headroom if test, md5(statamd5) sha1(stata1) sha256(stata256)
assert pymd5 == statamd5
assert py1   == stata1
assert py256 == stata256

pyhash, hash(md5 sha1 sha256) string(a little brown fox jumped the big fence)
return list
* shell printf "a little brown fox jumped the big fence" | sha256sum
* shell printf "a little brown fox jumped the big fence" | sha1sum
* shell printf "a little brown fox jumped the big fence" | md5sum

capture program drop hashstring
program hashstring, rclass
    version 16
    syntax anything, string(str asis)
    local okhashes md5 sha1 sha224 sha256 sha384 sha512
    foreach hash of local anything {
        if !`:list hash in okhashes' {
            disp `"unknown hash '`hash''; allowed: `okhashes'"'
            exit 198
        }
    }
    tempname frame
    frame create `frame'
    frame `frame' {
        qui set obs 1
        * mata st_addvar("str" + strofreal(strlen(st_local("string"))), "string")
        mata st_addvar("strL", "string")
        mata st_sstore(1, "string", st_local("string"))
        local genhash
        foreach hash of local anything {
            local genhash `genhash' `hash'(`hash')
        }
        shasum string, `genhash'
        foreach hash of local anything {
            local `hash' = `hash' 
            return local `hash': copy local `hash'
        }
    }
    frame drop `frame'
end
hashstring md5 sha1 sha256, string(a little brown fox jumped the big fence)
return list
