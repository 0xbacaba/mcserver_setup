#!/bin/bash

# ensure starting in setup directory
setup_dir=$(echo $0 | sed "s/`basename $0`\$//")
cd $setup_dir


source utils.sh

mc_version=$1
latest=`get_latest_version`
if [ -z "$mc_version" ]; then
	if [ -z "$latest" ]; then
		echo -n "Version: "
		read $mc_version
	else
		echo -n "Version [$latest]: "
		read mc_version
		mc_version=${mc_version:-"$latest"}
	fi
fi

if [ "$mc_version" == "all" ]; then
	for file in versions/*.jar; do
		if [ "$?" != "0" ]; then
			echo -en "\e[33mwarning: an error occured. Continue? [Y/n] \e[0m"
			read cont
			cont=${cont:-Y}
			if [ "${cont^^}" != "Y" ]; then
				exit
			fi
		fi
		version=`basename $file | sed 's/.jar$//'`
		echo updating $version
		install_paper_version $version
	done
	exit
fi

install_paper_version $mc_version
