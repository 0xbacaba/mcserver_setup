#!/bin/bash

function exists() {
	if [ -z "`command -v $1`" ]; then
		return 1
	fi
	return 0
}
function require() {
	local program=$1

	if ! exists $program; then
		echo -e "\e[31merror: $program is required but doesn't exist\e[0m" >&2
		exit
	fi
}
function require_optional() {
	local program=$1

	if ! exists $program; then
		echo -e "\e[33mwarning: $program doesn't exist, some features might not be available\e[0m" >&2
	fi
}
function is_fd_valid() {
	file_descriptor=$0

	if { true>&"$file_descriptor"; } 2>/dev/null; then
		return 0
	fi
	return 1
}

get_latest_version() {
	require sed

	# get the latest available server version
	echo `ls versions | grep '.jar' | sort -V | tail -n 1 | sed 's/.jar$//'`
}
install_paper_version() {
	local version=$1

	if ! exists curl || ! exists jq; then
		echo -e "\e[31merror: missing requirements to install paper. Please install \e[34mcurl\e[31m and \e[34mjq\e[0m"
		return 1
	fi

	local paperapi="https://api.papermc.io/v2/projects/paper"

	echo "fetching latest build for $version..."
	local latest_build=`curl "$paperapi/versions/$version/builds" -Ls | jq '.builds[-1].build'`

	if [ "$latest_build" == "null" ]; then
		echo -e "\e[31merror: no build for this version\e[0m"
		return 1
	fi
	echo -en "\e[32mgot build $latest_build. Proceed? [Y/n] \e[0m"
	read proceed
	local proceed=${proceed:-Y}

	if [ "${proceed^^}" != "Y" ]; then
		return 1
	fi

	echo "installing paper-$version-$latest_build.jar..."
	curl -fsSL "$paperapi/versions/$version/builds/$latest_build/downloads/paper-$version-$latest_build.jar" -o versions/$version.jar
	
	if [ "$?" != "0" ]; then
		echo -e "\e[31minstallation failed: $?\e[0m"
		return 1
	fi

	echo -e "\e[32minstallation successful\e[0m"
	return 0
}
