#!/bin/sh

set -eu

readonly DevToolsDir=$(dirname "$(echo $0 | sed -e "s,^\([^/]\),$(pwd)/\1,")")
readonly RootDir="${DevToolsDir}/.."

cd "${RootDir}"

for f in `find . -name '*.swift' -o -name '*.cc' | sed -e 's|./||' | grep -v '.pb.swift'`; do
    if head -n 4 $f | grep 'DO NOT EDIT' > /dev/null; then
        # If the first lines contain 'DO NOT EDIT', then
        # this is a generated file and we should not
        # try to check or edit the copyright message.
        # But: print the filename; all such files should be .pb.swift
        # files that we're not even looking at here.
        echo "DO NOT EDIT: $f"
    else
        tmp=$f~
        mv $f $tmp
        if head -n 10 $tmp | grep 'Copyright.*Apple' > /dev/null; then
            # This has a copyright message, update it
            # Edit the first line to have the correct filename
            head -n 1 $tmp | sed "s|// [^-]* - \(.*\)|// $f - \1|" >$f
            # Followed by the current copyright text:
            cat <<EOF >>$f
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
EOF
            # Followed by the body of the file
            # The copyright message ends at the first blank comment line after
            # the first line containing "LICENSE.txt":
            cat $tmp | sed -n '/LICENSE.txt/,$ p' | sed -n '/^\/\/$/,$ p' >> $f
            rm $tmp
        else
            # This does not have a copyright message, insert one
            echo "Inserting copyright >> $f"
            cat <<EOF >>$f
// $f - description
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

EOF
            cat $tmp >> $f
        fi
    fi
done
