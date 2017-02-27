#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script goes through the provided .xcarchive and generates the breakpad symbol file structure and symbols
# for both arm64/armv7 architectures. The resulting .zip can be directly uploaded to crash-stats for processing.

from __future__ import print_function

import argparse
import os
import subprocess
import sys
import zipfile
import plistlib

archs = ['arm64', 'armv7']

def get_scheme_version_and_buildid(archive):
    info = plistlib.readPlist(os.path.join(os.path.normpath(archive), "Info.plist"))
    return (info["SchemeName"], info["ApplicationProperties"]["CFBundleShortVersionString"], info["ApplicationProperties"]["CFBundleVersion"])

# Return the MachO full path from a .app/.framework path
def macho_path(path):
    return os.path.join(path, os.path.basename(path).split(".")[0])

# Get the path to the .dSYM file (Client.app.dSYM) for the given MachO binary (Client)
def get_dsym_path_for_macho(archive, macho_name): 
    try:
        stdout = subprocess.check_output(['find', archive, '-name', macho_name + '.*.dSYM'],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Finding dSYM error: %s' % e)   
        return None

    return stdout.rstrip()

def get_framework_paths(search_path):
    try:
        stdout = subprocess.check_output(['find', search_path, '-name', '*.framework'],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Finding frameworks error: %s' % e)   
        return None

    return filter(os.path.exists, map(macho_path, stdout.splitlines()))

# Find the app's executable name
def get_executable_path(archive):
    try:
        stdout = subprocess.check_output(['find', archive, '-name', '*.app'],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Finding executable error: %s' % e)   
        return None

    return macho_path(stdout.rstrip())

def demangle_symbol(symbol):
    # If symbol is Objective-C, ignore it
    if symbol.startswith("+[") or symbol.startswith("-["):
        return symbol

    try:
        stdout = subprocess.check_output(['xcrun', 'swift-demangle', symbol],
                                         stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Error demangling symbol <%s> : %s' % (symbol, e))   
        return symbol

    parts = stdout.split("-->")
    if len(parts) == 2:
        return parts[1] 
    else:
        return symbol

def process_file(dump_syms, path, arch, dsym):
    print("Generating symbols for %s (%s)" % (os.path.basename(path), arch))
    try:
        if dsym != '': 
            stdout = subprocess.check_output([dump_syms, '-a', arch, '-g', dsym, path],
                                             stderr=open(os.devnull, 'wb'))
        else:
            stdout = subprocess.check_output([dump_syms, '-a', arch, path],
                                             stderr=open(os.devnull, 'wb'))
    except subprocess.CalledProcessError as e:
        print('Error: %s' % e)
        return None, None, None
    bits = stdout.splitlines()[0].split(' ', 4)
    if len(bits) != 5:
        return None, None, None
    _, platform, cpu_arch, debug_id, debug_file = bits
    if debug_file.lower().endswith('.pdb'):
        sym_file = debug_file[:-4] + '.sym'
    else:
        sym_file = debug_file + '.sym'
    filename = os.path.join(debug_file, debug_id, sym_file)
    debug_filename = os.path.join(debug_file, debug_id, debug_file)

    # Run the symbols through the demanglers
    demangled_list = [] 
    for line in stdout.splitlines():
        parts = line.split(" ") 
        if parts[0] == 'PUBLIC':
            parts[3] = demangle_symbol(parts[3].strip()).strip()
        demangled_list.append(' '.join(parts) + '\n')

    return filename, ''.join(demangled_list), debug_filename

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dump_syms', help='Path to dump_syms binary')
    parser.add_argument('archive', help='Path to archive to get symbols from')
    parser.add_argument('--output-dir', default='.', help='Directory to place the resulting .zip file in') 
    args = parser.parse_args()

    app_info = get_scheme_version_and_buildid(args.archive)
    symbol_filename = "_".join(map(str, app_info)) + ".zip"
    symbol_filename = os.path.join(args.output_dir, symbol_filename)

    files = []
    app_framework_paths = get_framework_paths(args.archive) 

    if files != None:
      files.extend(app_framework_paths)
      executable_path = get_executable_path(args.archive)   

      if executable_path != None:
          files.append(executable_path)

    count = 0
    with zipfile.ZipFile(symbol_filename, 'w', zipfile.ZIP_DEFLATED) as zf:
        for f in files:
            dsym = get_dsym_path_for_macho(args.archive, os.path.basename(f).split(".")[0])  
            for arch in archs:
                filename, contents, debug_filename = process_file(args.dump_syms, f, arch, dsym)
                if not (filename and contents):
                    print('Error dumping symbols')
                    sys.exit(1)

                zf.writestr(filename, contents)
                zf.write(f, debug_filename)
                count += 2
    print('Added %d files to %s' % (count, symbol_filename))

if __name__ == '__main__':
    main()

