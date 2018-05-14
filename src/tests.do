* ----------------------------------------------------------------------------
* Project: shasum
* Program: tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Sun May  6 12:23:55 EDT 2018
* Updated: Mon May  7 14:04:07 EDT 2018
* Purpose: Unit tests for shasum
* Version: 0.1.4
* Manual:  help shasu

version 13
clear all
set more off
set varabbrev off
set seed 1729
set linesize 108

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
    log using tests_`c_os_'.log, text replace name(shasum_tests)

    local  progname tests
    local  start_time "$S_TIME $S_DATE"

    di _n(1)
    di "Start:        `start_time'"
    di "OS:           `c(os)'"
    di "Machine Type: `c(machine_type)'"

    * Tests
    * -----

    local gens md5(st_md5)       ///
               sha1(st_sha1)     ///
               sha224(st_sha224) ///
               sha256(st_sha256) ///
               sha384(st_sha384) ///
               sha512(st_sha512)

    qui import delimited `"../src/tests/make_hashes.csv"', varn(1) clear
        shasum make, `gens'
        check_hashes make not padded

    qui import delimited `"../src/tests/make2_hashes.csv"', varn(1) clear
        shasum make make, `gens'
        check_hashes make make not padded

    qui import delimited `"../src/tests/make_hashes_pad.csv"', varn(1) clear
        shasum make, `gens' pad
        check_hashes make padded

    qui import delimited `"../src/tests/make2_hashes_pad.csv"', varn(1) clear
        shasum make make, `gens' pad
        check_hashes make make padded

    clear
    qui import delimited `"../src/tests/meta_hashes.csv"', varn(1) clear
        shasum fname, `gens' file path(../src/tests/)
        check_hashes list of files

    clear
    qui import delimited `"../src/tests/meta_hashes.csv"', varn(1) clear
        gen fpath = "src/tests/"
        shasum fpath fname, `gens' file path(../)
        check_hashes list of paths and files
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
