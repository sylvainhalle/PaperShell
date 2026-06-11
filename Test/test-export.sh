#! /bin/bash

TMPDIR=""

setUp() {
	TMPDIR=$(mktemp -d)
}

testExport() {
	texlua ../Tools/psmod.lua --from .. export $TMPDIR
	assertEquals 0 $!
}

tearDown() {
	rm -rf $TMPDIR
}

# Load shUnit2.
. shunit2