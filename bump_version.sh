#!/bin/sh
usage() {
	echo "usage: bump-version <version-id>"
}

if [ $# -ne 1 ]; then
	usage
	exit 1
fi

if ! sed 's/^PUD_VERSION=.*$/PUD_VERSION='$1'/g' VERSION > .VERSION.new; then
	echo "Could not replace PUD_VERSION variable." >&2
	exit 2
fi

mv .VERSION.new VERSION
git add VERSION
git commit -m "Bumped version number to $1" VERSION
