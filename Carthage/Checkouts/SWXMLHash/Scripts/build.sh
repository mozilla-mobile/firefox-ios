#!/bin/sh

set -ev

xctool -scheme "SWXMLHash iOS" clean build test -sdk iphonesimulator
