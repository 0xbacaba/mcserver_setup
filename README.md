# Minecraft Server Setup
-------------------

### Usage:
```bash
cd $server_root
git clone https://github.com/LetsDuck2210/mcserver_setup setup


# Install server versions to $server_root/setup/versions. 
# The script can automatically install paper servers for unavailable versions
# Example:
version=1.21.1
build=39
url="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar"
curl -fsSL $url -o $server_root/setup/versions/1.21.1.jar


# creating a server
$server_root/setup/setup.sh


# running a server
cd $server_root/<server_name>
./start.sh 
```

### Adding plugins
Plugins should be placed in `$server_root/setup/plugins` and linked to `$server_root/setup/plugins/$version` accordingly

Example:
```bash
curl -fsSL https://hangarcdn.papermc.io/plugins/EngineHub/WorldEdit/versions/7.3.6/PAPER/worldedit-bukkit-7.3.6.jar -o $server_root/setup/plugins/worldedit-7.3.6.jar

ln -rs $server_root/setup/plugins/worldedit-7.3.6.jar $server_root/setup/plugins/$version/worldedit.jar
```

If no plugins folder for a specific version exists, the script will either:
1. Create a new folder for the version, linking all plugins in the `$server_root/setup/plugins` directory
2. Create a new folder for the version without linking any plugins
3. Create a new folder in the server directory without linking or copying anything


### Configuring defaults:
any files in `$server_root/setup/defaults` will be copied to new servers \
any occurences of {name}, {version}, etc. in these files will be replaced by the name, the version etc. of the new server


