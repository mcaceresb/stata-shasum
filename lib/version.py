#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
from datetime import datetime, date
from os import path, makedirs, unlink
from zipfile import ZipFile
from shutil import copy2

parser = argparse.ArgumentParser()
parser.add_argument('bump',
                    nargs    = 1,
                    type     = str,
                    metavar  = 'BUMP',
                    help     = "What to bump (major, minor, patch)")
parser.add_argument('--dry',
                    dest     = 'dry',
                    action   = 'store_true',
                    help     = "Dry run (do not run)",
                    required = False)
args = vars(parser.parse_args())

# ---------------------------------------------------------------------
# Config

config_token   = "CrossPlatformCompatibilityCookie"
config_version = "0.2.1"
config_date = date(2022, 10, 9)
config_files = [
    ('lib/version.py', 'config_version = "{major}.{minor}.{patch}"'),
    ('lib/version.py', f'config_date = date({{date:%Y, {config_token}%m, {config_token}%d}})'),
    ('.appveyor.yml', 'generic-{major}.{minor}.{patch}'),
    ('README.md', 'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('src/shasum.pkg', 'v {major}.{minor}.{patch}'),
    ('src/shasum.pkg', 'd Distribution-Date: {date:%Y%m%d}'),
    ('src/stata.toc', 'v {major}.{minor}.{patch}'),
    ('docs/shasum.sthlp', 'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('src/shasum.ado', 'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('../src/tests.do', 'version {major}.{minor}.{patch}')
]

config_build = {
    'shasum': {
        'build': 'build',
        'outzip': f'releases/shasum-{config_version}.zip',
        'files': [
            'src/shasum.ado',
            'docs/shasum.sthlp',
            'src/stata.toc',
            'src/shasum.pkg',
            'src/tests.do',
            'lib/plugin/shasum_macosx.plugin',
            'lib/plugin/shasum_unix.plugin',
            'lib/plugin/shasum_windows.plugin',
            'changelog.md'
        ]
    }
}

# ---------------------------------------------------------------------
# Bump


def main(bump, dry = False):
    args = ['major', 'minor', 'patch', 'build', 'build-zip']
    if bump not in args:
        msg = f"'{bump}' uknown; can only bump: {', '.join(args[:3])}"
        raise Warning(msg)

    if bump in ['build', 'build-zip']:
        make_build(config_build, dry, '-zip' in bump)
    else:
        current_kwargs, update_kwargs = bump_kwargs(bump, config_version, config_date)
        for file, string in config_files:
            bump_file(file, string, current_kwargs, update_kwargs, dry)


def make_build(standalone, dry=False, inzip=False):
    for label in standalone.values():
        files  = label['files']
        outzip = label['outzip'] if 'outzip' in label else 'standalone'
        build  = label['build'] if 'build' in label else 'standalone'

        if dry:
            if inzip:
                for f in files:
                    print(f'{f} -> {outzip}')
            else:
                for f in files:
                    print(f'{f} -> {build}/')
        else:
            if not path.isdir(build):
                makedirs(build)

            if inzip and path.isfile(outzip):
                unlink(outzip)

            if inzip:
                with ZipFile(outzip, 'w') as zf:
                    for f in files:
                        print(f'{f} -> {outzip}')
                        zf.write(f, path.basename(f))
            else:
                for f in files:
                    print(f'{f} -> {build}/')
                    copy2(f, build)


def bump_file(file, string, current, update, dry = False):
    find = (
        string
        .format(**current)
        .replace(config_token + "0", "")
        .replace(config_token, "")
    )
    with open(file, 'r') as fh:
        lines = fh.readlines()
        if find not in ''.join(lines):
            print(f'WARNING: nothing to bump in {file}')

        replace = (
            string
            .format(**update)
            .replace(config_token + "0", "")
            .replace(config_token, "")
        )
        ulines = []
        for line in lines:
            if find in line:
                print(f'{file}: {find} -> {replace}')
                ulines += [line.replace(find, replace)]
            else:
                ulines += [line]

    if not dry:
        with open(file, 'w') as fh:
            fh.write(''.join(ulines))


def bump_kwargs(bump, config_version, config_date):
    today = datetime.now()
    major, minor, patch = config_version.split('.')
    umajor, uminor, upatch = bump_sever(bump, major, minor, patch)

    current_kwargs = {
        'major': major,
        'minor': minor,
        'patch': patch,
        'date': config_date
    }

    update_kwargs = {
        'major': umajor,
        'minor': uminor,
        'patch': upatch,
        'date': today
    }

    return current_kwargs, update_kwargs


def bump_sever(bump, major, minor, patch):
    if bump == 'major':
        return str(int(major) + 1), '0', '0'
    elif bump == 'minor':
        return major, str(int(minor) + 1), '0'
    elif bump == 'patch':
        return major, minor, str(int(patch) + 1)
    else:
        return major, minor, patch


if __name__ == "__main__":
    main(args['bump'][0], args['dry'])
