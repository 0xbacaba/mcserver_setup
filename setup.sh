#!/bin/bash

exists() {
	if [ -z "`command -v $1`" ]; then
		return 1
	fi
	return 0
}
require() {
	local program=$1
	
	if ! exists $program; then
		echo -e "\e[31merror: $program is required but doesn't exist\e[0m"
		exit
	fi
}
require_optional() {
	local program=$1

	if ! exists $program; then
		echo -e "\e[33mwarning: $program doesn't exist, some features might not be available\e[0m"
	fi
}

require sed
require_optional curl
require_optional jq

# ensure starting in setup directory
setup_dir=$(echo $0 | sed "s/`basename $0`\$//")
cd $setup_dir


install_paper_version() {
	local version=$1

	if ! exists curl || ! exists jq; then
		echo -e "\e[31merror: missing requirements to install paper. Please install \e[34mcurl\e[31m and \e[34mjq\e[0m"
		exit
	fi

	local paperapi="https://api.papermc.io/v2/projects/paper"

	echo "fetching latest build for $version..."
	local latest_build=`curl "$paperapi/versions/$version/builds" -Ls | jq '.builds[-1].build'`

	if [ "$latest_build" == "null" ]; then
		echo -e "\e[31merror: no build for this version\e[0m"
		exit
	fi
	echo -en "\e[32mgot build $latest_build. Proceed? [Y/n] \e[0m"
	read proceed
	local proceed=${proceed:-Y}

	if [ "${proceed^^}" != "Y" ]; then
		exit
	fi

	echo "installing paper-$version-$latest_build.jar..."
	curl -fsSL "$paperapi/versions/$version/builds/$latest_build/downloads/paper-$version-$latest_build.jar" -o versions/$version.jar
	
	if [ "$?" != "0" ]; then
		echo -e "\e[31minstallation failed: $?\e[0m"
		exit
	fi

	echo -e "\e[32minstallation successful\e[0m"
	get_latest_version
}
get_latest_version() {
	# get the latest available server version
	latest=`ls versions | grep '.jar' | sort -V | tail -n 1 | sed 's/.jar$//'`
}

get_latest_version

if [ -z "$latest" ]; then
	echo -en "\e[33mwarning: no server executables found. Would you like to install paper? [Y/n] \e[0m"
	read install_paper
	install_paper=${install_paper:-Y}

	if [ "${install_paper^^}" != "Y" ]; then
		exit
	fi

	read -p "Minecraft Version: " install_version

	install_paper_version $install_version
fi

read -p "Version [$latest]: " version
version=${version:-$latest}

if [ ! -f "versions/$version.jar" ]; then
	echo -en "\e[33mwarning: $version doesn't exist. Install paper? [Y/n] \e[0m"
	read install_paper
	install_paper=${install_paper:-Y}

	if [ "${install_paper^^}" != "Y" ]; then
		exit
	fi
	
	install_paper_version $version
fi

if [ ! -d "plugins/$version" ]; then
	echo -e "\e[33mwarning: no plugins for this version\e[0m"
	read -p "Link default plugins? [Y/n] " link_plugins
	link_plugins=${link_plugins:-Y}

	if [ "${link_plugins^^}" == "Y" ]; then
		mkdir -p "plugins/$version"
		ln -rs "plugins/*.jar" "plugins/$version"

		# print plugin count
		plugin_count=`ls "plugins/$version" | wc -l`
		if [ "$plugin_count" == "1" ]; then
			echo -e "\e[32m1 plugin linked\e[0m"
		else
			echo -e "\e[32m$plugin_count plugins linked\e[0m"
		fi
	else
		read -p "Create linked directory? [Y/n] " link_dir
	fi
fi

read -p "Name: " name

server_dir="../$name"

# check if $server_dir is already a directory or file
if [ -d "$server_dir" ] || [ -f "$server_dir" ]; then
	echo -en "\e[33mwarning: directory already exists. Continue? [Y/n]\e[0m "
	read ignore_warning
	ignore_warning=${ignore_warning:-Y}

	if [ "${ignore_warning^^}" != "Y" ]; then
		exit
	fi
fi

mkdir -p "$server_dir"

echo "linking server and plugins"
ln -frs "versions/$version.jar" "$server_dir/server.jar"

link_dir=${link_dir:-Y}

if [ "${link_dir^^}" == "Y" ]; then
	mkdir -p "plugins/$version"
	ln -frs "plugins/$version" "$server_dir/plugins"
else
	mkdir -p "$server_dir/plugins"
fi


# copy files to intermediary directory
intermed="$server_dir/temp"
mkdir -p "$intermed"

for file in "defaults"/*; do
	echo -e "\e[38;5;8mcopying $file...\e[0m"
	newfile="$intermed/`basename $file`"
	cp -r $file $newfile
done

# fill in variables in default files
variables=(version name)
echo "replacing variables: ${variables[*]}"
for file in `find "$intermed" -type f`; do
	if [ -f "$file" ]; then
		for var in ${variables[*]}; do
			sed -i "s|{$var}|${!var}|g" "$file"
		done
	fi
done

# remove intermediary directory
mv "$intermed"/* "$server_dir"
rmdir $intermed

echo -e "\e[32msetup complete\e[0m"
