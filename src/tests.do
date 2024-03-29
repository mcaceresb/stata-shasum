* ----------------------------------------------------------------------------
* Project: shasum
* Program: tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Sun May  6 12:23:55 EDT 2018
* Updated: Sun Oct 09 20:04:09 EDT 2022
* Purpose: Unit tests for shasum
* Version: 0.2.2
* Manual:  help shasum

version 14.2
clear all
set more off
set varabbrev off
set seed 1729
set linesize 108
if "`c(username)'" == "statauser" {
    global ROOT /shasum/src/tests
}
else {
    global ROOT ../src/tests
}

capture program drop main
program main

    * Set up
    * ------

    if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) {
        local c_os_ macosx
    }
    else {
        local c_os_: di lower("`c(os)'")
    }
    log using ${ROOT}/tests_`c_os_'.log, text replace name(shasum_tests)

    local  progname tests
    local  start_time "$S_TIME $S_DATE"

    di _n(1)
    di "Start:        `start_time'"
    di "OS:           `c(os)'"
    di "Machine Type: `c(machine_type)'"

    * Tests
    * -----

    cap which shasum
    if _rc net install shasum, from(${ROOT}/../../build)

    local gens md5(st_md5)       ///
               sha1(st_sha1)     ///
               sha224(st_sha224) ///
               sha256(st_sha256) ///
               sha384(st_sha384) ///
               sha512(st_sha512)

    * Variable hashing
    * ----------------

    disp _n(2) "{hline 80}" _n(1) "Varlist hashing" _n(2)

    qui import delimited `"${ROOT}/make_hashes.csv"', varn(1) clear
        shasum make, `gens'
        check_hashes make not padded

    qui import delimited `"${ROOT}/make2_hashes.csv"', varn(1) clear
        shasum make make, `gens'
        check_hashes make make not padded

    qui import delimited `"${ROOT}/make_hashes_pad.csv"', varn(1) clear
        shasum make, `gens' pad
        check_hashes make padded

    qui import delimited `"${ROOT}/make2_hashes_pad.csv"', varn(1) clear
        shasum make make, `gens' pad
        check_hashes make make padded

    * File list hashing
    * -----------------

    disp _n(2) "{hline 80}" _n(1) "File list hashing" _n(2)

    clear
    qui import delimited `"${ROOT}/meta_hashes.csv"', varn(1) clear
        shasum fname, `gens' filelist path(${ROOT}/)
        check_hashes list of files

    clear
    qui import delimited `"${ROOT}/meta_hashes.csv"', varn(1) clear
        gen fpath = "${ROOT}/"
        shasum fpath fname, `gens' filelist path(../)
        check_hashes list of paths and files

    * File list hashing - strL
    * ------------------------

    disp _n(2) "{hline 80}" _n(1) "File list hashing - strL" _n(2)

    clear
    qui import delimited `"${ROOT}/meta_hashes.csv"', varn(1) clear
        gen strL fbinary = ""
        forvalues i = 1 / `=_N' {
            replace fbinary = fileread(`"${ROOT}/`=fname[`i']'"') in `i'
        }
        cap noi shasum fbinary, `gens'
        if ( `c(stata_version)' < 14.1 ) {
            assert _rc == 17002
        }
        else {
            check_hashes list of files (strL)
        }

    * Individual file hashing
    * -----------------------

    disp _n(2) "{hline 80}" _n(1) "File hashing" _n(2)

    clear
    local hashes md5 sha1 sha224 sha256 sha384 sha512
    qui import delimited `"${ROOT}/meta_hashes.csv"', varn(1) clear
        local files
        forvalues i = 1 / `=_N' {
            local files `files' `=fname[`i']'
            foreach hash of local hashes {
                local h`i'_`hash' `=`hash'[`i']'
            }
        }

    clear
    local i 0
    foreach file of local files {
        local ++i
        disp _n(1) `"`file'"'
        qui shasum, file(`file', `hashes') path(${ROOT}/)
        foreach hash of local hashes {
            cap noi assert `"`r(`hash')'"' == `"`h`i'_`hash''"'
            if ( _rc ) {
                disp as err "    shasum_test (failed): `hash' yield an unexpected result"
                exit _rc
            }
            else {
                disp as txt "    shasum_test (passed): `hash'"
            }
        }
    }
end

capture program drop check_hashes
program check_hashes
    disp as txt _n(1) "Checking hashes for `0'" _n(1)

    foreach hash in md5 sha1 sha224 sha256 sha384 sha512 {
        cap noi assert `hash' == st_`hash'
        if ( _rc ) {
            disp as err "    shasum_test (failed): `hash' yield an unexpected result"
            exit _rc
        }
        else {
            disp as txt "    shasum_test (passed): `hash'"
        }
    }
end

* ---------------------------------------------------------------------
* Run the things

main
