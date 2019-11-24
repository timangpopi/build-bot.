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

export outdir="out/target/product/$device"

# Now Compile

mkdir "$ROM"
cd "$ROM"

echo "Sync started for "$manifest_url""
../telegram -M "Sync Started for ["$ROM"]("$manifest_url")"
SYNC_START=$(date +"%s")
#trim_darwin >/dev/null   2>&1
#repo sync --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all) -q 2>&1 >>logwe 2>&1
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags #2>&1 >>logwe 2>&1
bash ../clone.sh

SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))
if [ -e frameworks/base ]; then
    echo "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    echo "Build Started"
    ../telegram -M "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"

    ../telegram -M "Build Started
ROM : ""$ROM""
Android : "$branch"
Device : "$device"
Brand : "$oem"
Type : UNOFFICIAL
Dev : ""$KBUILD_BUILD_USER""
Build Date : ""$(env TZ=$timezone date)""
"

    BUILD_START=$(date +"%s")

    source build/envsetup.sh >/dev/null  2>&1
    source ../config.sh
    if [ -e device/"$oem"/"$device" ]; then
        python3 ../dependency_cloner.py
    fi
    lunch "$rom_vendor_name"_"$device"-userdebug >/dev/null  2>&1
    make bacon -j4
    BUILD_END=$(date +"%s")
    BUILD_DIFF=$((BUILD_END - BUILD_START))

    export finalzip_path=$(ls "$outdir"/*201*.zip | tail -n -1)
    export zip_name=$(echo "$finalzip_path" | sed "s|"$outdir"/||")
    export tag=$( echo "$zip_name" | sed 's|.zip||')
    if [ -e "$finalzip_path" ]; then
        echo "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

        echo "Uploading"

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
echo "end build"
