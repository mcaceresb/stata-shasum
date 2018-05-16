Change Log
==========

## shasum-0.1.4 (2018-05-13)

### Features

- Added options -filelist- and -path()- to hash a list of files
- Added options -file()- and -path()- to hash a single file

### Bug fixes

- Initialize hash strings as blank, not empty.

## shasum-0.1.3 (2018-05-07)

### Bug fixes

- This was compiled with static libraries on Windows, OSX, and Linux so
  it is not necessary to add a dependencies option.

## shasum-0.1.2 (2018-05-07)

### Features

- Added OSX version

## shasum-0.1.1 (2018-05-07)

### Bug fixes

- Strings are now concatenated by default.
- Option `pad` retains the old behavior and pads with null characters, '\0'

## shasum-0.1.0 (2018-05-07)

### Features

- `shasum` function provides wrapper for OpenSSL hashes.
- Output MD5, SHA1, SHA224, SHA256, SHA384, and SHA512 of a varlist.
