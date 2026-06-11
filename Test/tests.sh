#! /bin/bash

export PAPERSHELL_HOME="$(realpath $(pwd)/../)"
TMPDIR=""
PS="texlua $PAPERSHELL_HOME/Tools/psmod.lua"

setUp() {
	TMPDIR=$(mktemp -d)
	pushd $TMPDIR
}

testRoot() {
	  touch .papershell
	  $PS 1> /dev/null 2> /dev/null
	  assertEquals 1 $?
}

testNoRoot() {
	  $PS list 1> /dev/null 2> /dev/null
	  assertEquals 3 $?
}

testInit() {
	  $PS init 1> /dev/null 2> /dev/null
	  assertEquals 0 $?
	  assertTrue  "[ -e .papershell ]"
	  assertTrue  "[ -d Source ]"
	  assertTrue  "[ -d Tools ]"
	  assertFalse "[ -d Test ]"
}

testExport() {
	  $PS init #1> /dev/null 2> /dev/null
	  $PS export #1> /dev/null 2> /dev/null
	  assertEquals 0 $?
	  assertTrue  "[ -e paper.zip ]"
	  contents=$(unzip -l paper.zip)
	  assertTrue  '[[ "$contents" == *"paper.tex"* ]]'
	  assertFalse '[[ "$contents" == *"paper.pdf"* ]]'
}

tearDown() {
	popd
	rm -rf $TMPDIR
}

# Load shUnit2.
. shunit2