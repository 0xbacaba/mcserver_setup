#!/bin/bash

function is_windows() {
	if [[ `uname -o` == *"Linux"* ]]; then
		return 1
	fi

	return 0
}
function to_win_path() {
	path=$1

	echo "$path" | sed 's/\//\\/g'
}
function win_symlink() {
	target=$1
	link_name=$2

	win_target=`to_win_path $target`
	win_link_name=`to_win_path $link_name`

	if [ -f $target ]; then
		# symbolic file links don't seem to be supported
		powershell.exe -c "cmd.exe /c mklink /H $win_link_name $win_target"
	elif [ -d $target ]; then
		powershell.exe -c "cmd.exe /c mklink /J $win_link_name $win_target"
	else
		echo -en "\033[31merror: $target doesn't exist\033[0m"
		return 1
	fi

	return $?
}
function symlink() {
	target=$1
	link_name=$2
	if ! is_windows; then
		ln -rs $target $link_name
		return $?
	fi

	win_symlink $target $link_name
	return $?
}
function symlink_force() {
	target=$1
	link_name=$2

	if ! is_windows; then
		ln -frs $target $link_name
		return $?
	fi

	rm -rf $link_name
	win_symlink $target $link_name
}
function exists() {
	if [ -z "`command -v $1`" ]; then
		return 1
	fi
	return 0
}
function directory_contains() {
	local directory="$1"
	local glob="$2"

	if [ -z "`find "$directory" -maxdepth 1 -name "$glob"`" ]; then
		return 1
	fi
	return 0
}
function require() {
	local program=$1

	if ! exists $program; then
		echo -e "\033[31merror: $program is required but doesn't exist\033[0m" >&2
		exit
	fi
}
function require_optional() {
	local program=$1

	if ! exists $program; then
		echo -e "\033[33mwarning: $program doesn't exist, some features might not be available\033[0m" >&2
	fi
}
function is_fd_valid() {
	file_descriptor=$0

	if { true>&"$file_descriptor"; } 2>/dev/null; then
		return 0
	fi
	return 1
}

function ask_user_select_files() {
	subdir="$1"
	pattern="$2"

	if ! directory_contains "$subdir" "$pattern"; then
		return 0
	fi

	previous_dir=`pwd`
	if [ ! -z "$subdir" ]; then
		cd $subdir
	fi

	PS3="$3"
	default_prompt="Select a file or type q to quit: "

	PS3=${PS3:-$default_prompt}

	selected_files=()
	selecting="true"
	while [ ! -z $selecting ]; do
		files=()
		# Only list the files that have not been selected
		for file in $pattern; do
			[[ ! " ${selected_files[*]} " =~ " $file " ]] && files+=($file)
		done
		if [ -z $files ]; then
			break
		fi

		select file in "${files[@]}"; do
			if [[ -n $file ]]; then
				echo $file
				selected_files+=("$file")
				break
			fi
			selecting=""
			break
		done
	done
	cd $previous_dir
}

get_latest_version() {
	require sed

	# get the latest available server version
	echo `ls versions | grep '.jar' | sort -V | tail -n 1 | sed 's/.jar$//'`
}
install_paper_version() {
	local version=$1

	if ! exists curl || ! exists jq; then
		echo -e "\033[31merror: missing requirements to install paper. Please install \033[34mcurl\033[31m and \033[34mjq\033[0m"
		return 1
	fi

	local paperapi="https://api.papermc.io/v2/projects/paper"

	echo "fetching latest build for $version..."
	local latest_build=`curl "$paperapi/versions/$version/builds" -Ls | jq '.builds[-1].build'`

	if [ "$latest_build" == "null" ]; then
		echo -e "\033[31merror: no build for this version\033[0m"
		return 1
	fi
	echo -en "\033[32mgot build $latest_build. Proceed? [Y/n] \033[0m"
	read proceed
	local proceed=${proceed:-Y}

	if [ "${proceed^^}" != "Y" ]; then
		return 1
	fi

	echo "installing paper-$version-$latest_build.jar..."
	curl -fsSL "$paperapi/versions/$version/builds/$latest_build/downloads/paper-$version-$latest_build.jar" -o versions/$version.jar
	
	if [ "$?" != "0" ]; then
		echo -e "\033[31minstallation failed: $?\033[0m"
		return 1
	fi

	echo -e "\033[32minstallation successful\033[0m"
	return 0
}
