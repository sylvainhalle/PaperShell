#! /bin/bash

#   PaperShell, a flexible LaTeX environment for scientific papers
#   Copyright (C) 2015-2026  Sylvain Hallé
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

# --------------------------
# Unit tests.
# Running this test suite requires shUnit2: https://github.com/kward/shunit2
# --------------------------
    
export PAPERSHELL_HOME="$(realpath $(pwd)/../)"
TMPDIR=""
PS="texlua $PAPERSHELL_HOME/Tools/psmod.lua"
tostdout=/dev/stdout
tostderr=/dev/stderr
verbose=true
textidote=$(which textidote; echo $?)

# If the verbose flag is false, redirect output to /dev/null
if [ "$verbose" == "false" ]; then
	tostdout=/dev/null
	tostderr=/dev/null
fi

setUp() {
	TMPDIR=$(mktemp -d)
	pushd $TMPDIR > /dev/null
}

testRoot() {
	  touch .papershell
	  $PS 1> $tostdout 2> $tostderr
	  assertEquals "PaperShell shoud expect a command" 1 $?
}

testNoRoot() {
	  $PS list 1> $tostdout 2> $tostderr
	  assertEquals "PaperShell should complain about lack of a root folder" 3 $?
}

testInit() {
	  $PS init 1> $tostdout 2> $tostderr
	  assertEquals 0 $?
	  assertTrue  "A .papershell file should be added"   "[ -e .papershell ]"
	  assertTrue  "The Source folder should be copied"   "[ -d Source ]"
	  assertTrue  "The main file should be copied"       "[ -e Source/paper.tex ]"
	  assertTrue  "The Tools folder should be copied"    "[ -d Tools ]"
	  assertFalse "The Test folder should not be copied" "[ -d Test ]"
}

testExport() {
	  $PS init 1> $tostdout 2> $tostderr
	  touch Source/paper.pdf # Simulate the compilation
	  $PS export 1> $tostdout 2> $tostderr
	  assertEquals "The operation should exit without error" 0 $?
	  assertTrue  "The archive paper.zip should be created" "[ -e paper.zip ]"
	  contents=$(unzip -l paper.zip)
	  assertTrue  "The archive contains the source" '[[ "$contents" == *"paper.tex"* ]]'
	  assertFalse "The archive does not contain the compiled file" '[[ "$contents" == *"paper.pdf"* ]]'
}

testWC() {
	$PS init 1> $tostdout 2> $tostderr
	result=$($PS wc)
	assertEquals "The operation should exit without error" 0 $?
	assertTrue "A word count should be printed" '[[ "$result" =~ ^.*[0-9]+\ word\(s\)[[:space:]]*$ ]]'
}

testCheck() {
	$PS init 1> $tostdout 2> $tostderr
	$PS check
	#result=$($PS check)
	assertEquals "The operation should exit without error" 0 $?
	assertTrue "A report should be produced" "[ -e textidote.html ]"
	assertTrue "The report is not empty"     "[ -s textidote.html ]"
}

tearDown() {
	popd 1> /dev/null 2> /dev/null
	rm -rf $TMPDIR
}

# Load shUnit2.
. shunit2