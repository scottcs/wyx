#!/bin/sh
program='wyx'
versvar=$(echo $program | tr a-z A-Z)

usage() {
	echo "usage: build <directory>"
}

if [ $# -eq 0 ]; then
	directory="/Users/scott/hub/Inbox"
elif [ $# -eq 1 ]; then
	directory=$1
else
	usage
	exit 1
fi

if [ ! -d $directory ]; then
	echo "Directory not found: $directory"
	exit 2
fi

version=$(cat VERSION | sed 's/'$versvar'_VERSION=//')

if [ "$version" == "" ]; then
	echo "Invalid version"
	exit 2
fi

lovefile="${directory}/${program}_v${version}.love"

if [ -s main.lua ]; then
	echo "Building $lovefile"

	cp -f main.lua .build-main.lua

	if ! sed 's/^--debug = nil$/debug = nil/g' main.lua > .main.lua.new; then
		echo "Could not disable debug in main.lua." >&2
	else
		rm main.lua
		mv .main.lua.new main.lua
	fi

	if ! sed 's/^doProfile = .*$/doProfile = false/g' main.lua > .main.lua.new; then
		echo "Could not disable profiling in main.lua." >&2
	else
		rm main.lua
		mv .main.lua.new main.lua
	fi

	if [ -w .main.lua.new ]; then
		rm .main.lua.new
	fi
else
	echo "Error: no main.lua found."
	exit 2
fi

if [ ! -e .gitignore ]; then
	echo '*/.DS_Store' > .gitignore
fi

if ! zip $lovefile -q -r * -x@.gitignore -x*.sh ; then
	echo "Error creating .love file: $lovefile"
	exit 2
fi

rm main.lua
mv .build-main.lua main.lua

open -R $lovefile
