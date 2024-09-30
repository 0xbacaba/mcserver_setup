#!/bin/bash

source utils.sh

require_optional curl
require_optional jq

# ensure starting in setup directory
setup_dir=$(echo $0 | sed "s/`basename $0`\$//")
cd $setup_dir

latest=`get_latest_version`

if [ -z "$latest" ]; then
	echo -en "\e[33mwarning: no server executables found. Would you like to install paper? [Y/n] \e[0m"
	read install_paper
	install_paper=${install_paper:-Y}

	if [ "${install_paper^^}" != "Y" ]; then
		exit
	fi

	read -p "Minecraft Version: " install_version

	if ! install_paper_version $install_version; then
		exit
	fi
	latest=`get_latest_version`
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
	
	if ! install_paper_version $version; then
		exit
	fi
fi

if [ ! -d "plugins/$version" ]; then
	echo -e "\e[33mwarning: no plugins for this version\e[0m"
	read -p "Link default plugins? [Y/n] " link_plugins
	link_plugins=${link_plugins:-Y}

	if [ "${link_plugins^^}" == "Y" ]; then
		mkdir -p "plugins/$version"
		symlink "plugins/*.jar" "plugins/$version"

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
symlink_force "versions/$version.jar" "$server_dir/server.jar"

link_dir=${link_dir:-Y}

if [ "${link_dir^^}" == "Y" ]; then
	mkdir -p "plugins/$version"
	symlink_force "plugins/$version" "$server_dir/plugins"
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
