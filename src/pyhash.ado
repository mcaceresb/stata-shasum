*! version 0.2.2 11Oct2022 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Wrapper for Python's hashlib

capture program drop pyhash
program pyhash, rclass
    version 16
    syntax [varlist] [if] [in], HASHes(str) [GENerate(str) string(str asis) replace]

    if `"`string'"' == "" & "`varlist'" == "" {
        disp as err "Nothing to do; add varlist or -string()-"
        exit 198
    }

    if `"`string'"' == "" {
        if `:list sizeof hashes' != `:list sizeof generate' {
            disp as err "As many hashas as variables to generate are required"
            exit 198
        }

        local add
        foreach gen in `generate' {
            local addvar = 1
            if "`replace'" == "" {
                confirm new var `gen'
            }
            else {
                confirm name `gen'
                cap confirm new var `gen'
                local addvar = _rc == 0
            }
            local add `add' `addvar'
        }

        if `"`if'`in'"' != "" marksample touse, novarlist
    }

    python: import hashlib
    python: from numbers import Number
    python: from struct import pack
    python: packnum = lambda val: pack("d", float(val))
    python: packstr = lambda val: pack(f'{len(val)}s', bytes(val.encode()))
    python: packval = lambda val: packnum(val) if isinstance(val, Number) else packstr(val)

    if `"`string'"' == "" {
        python: from sfi import Data
        python: array   = Data.get("`varlist'".split(' '), selectvar="`touse'")
        python: packrow = lambda row: b''.join(packval(val) for val in row)

        forvalues i = 1 / `:list sizeof hashes' {
            local addvar: word `i' of `add'
            local hash:   word `i' of `hashes'
            local gen:    word `i' of `generate'
            python: hashes = [hashlib.`hash'(packrow(row)).hexdigest() for row in array]
            if `addvar' {
                python: Data.addVarStr("`gen'", len(hashes[0]))
            }
            else {
                qui replace `gen' = ""
            }
            python: Data.store("`gen'", None, hashes, selectvar="`touse'")
        }
    }

    if `"`string'"' != "" {
        python: from sfi import Macro
        foreach hash of local hashes {
            python: Macro.setLocal("`hash'", hashlib.`hash'(Macro.getLocal("string").encode()).hexdigest())
            return local `hash': copy local `hash'
        }
    }
end
