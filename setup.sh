#!/bin/sh

# run this script once to initialize the support modules

msg() {
	echo "=> " $1
}

flot() {
	msg "Setting up flot ..."
	mkdir -p support/public/js/
	cd support/flot
	make
	cp *.min.* ../public/js/
}

msg "Initializing git submodules ..."

git submodule init
git submodule update

flot

