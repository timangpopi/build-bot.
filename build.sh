#!/bin/bash
#
# buildbot script for compiling android ROMs using drone CI

source ./config.sh

# Configure git
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USER"

#export TELEGRAM_TOKEN=$(cat /tmp/tg_token)
#export TELEGRAM_CHAT=$(cat /tmp/tg_chat)
export GITHUB_TOKEN=$(cat /tmp/gh_token)

chmod +x github-release
chmod +x telegram
mkdir -p ~/bin
wget 'https://storage.googleapis.com/git-repo-downloads/repo' -P ~/bin
chmod +x ~/bin/repo
export PATH=~/bin:$PATH
export USE_CCACHE=1
sudo apt-get update
sudo apt-get install liblz4-dev

function trim_darwin() {
    cd .repo/manifests
    cat default.xml | grep -v darwin  >temp  && cat temp >default.xml  && rm temp
    git commit -a -m "Magic"
    cd ../
    cat manifest.xml | grep -v darwin  >temp  && cat temp >manifest.xml  && rm temp
    cd ../

# Now Compile
mkdir "$ROM"
cd "$ROM"

export outdir="out/target/product/$device"

# Initialize repo
repo init -u "$manifest_url" -b "$branch" --depth 1 &> /dev/null
trim_manifest &> /dev/null
echo "Sync started for $manifest_url"
#telegram -M "Sync Started for [$ROM]($manifest_url)"

# Reset bash timer and begin syncing
SECONDS=0
if repo sync --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all) &> /dev/null; then
	# Syncing completed, clone custom repos if any
	bash ./clone.sh

	echo -e "\n\nSync completed successfully in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
    echo "Build Started"
    #telegram -M "Sync completed successfully in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)

#Build Started: [See Progress]($ci_url)"
	
	# Reset bash timer and begin compilation
    SECONDS=0
    source build/envsetup.sh &> /dev/null
    if [ -e "device/$oem/$device" ]; then python3 /drone/src/dependency_cloner.py; fi
    lunch $rom_vendor_name_$device-userdebug &> /dev/null

    if mka bacon | grep $device; then
		# Build completed succesfully, upload it to github
		export finalzip_path=$(ls "$outdir/*2019*.zip" | tail -n -1)
		export zip_name=$(basename -s "$finalzip_path")
        echo -e "\n\nBuild completed successfully in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
        echo "Uploading..."

        #github-release "$release_repo" "$zip_name" "master" "$ROM for $device

#Date: $(env TZ="$timezone" date)" "$finalzip_path"

        echo "Uploaded succesfully to $(curl -sT "$zippath" https://transfer.sh/"$zip_name".zip)"

        #telegram -M "Build completed successfully in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)

#Download: [$zip_name](https://github.com/$release_repo/releases/download/$zip_name/"$zip_name".zip)"

    else
		# Build failed
        echo -e "\n\nBuild failed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !!"
        #telegram -N -M "ALERT: Build failed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
        exit 1
    fi
else
	# Sync failed
    echo -e "\n\nSync failed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!!"
    #telegram -N -M "ALERT: Sync failed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
    exit 1
fi
#End build
