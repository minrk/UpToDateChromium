#!/bin/sh

removeafter=false
downloads="$HOME/Downloads"
installdir="/Applications"

notify=`which growl` # GrowlScript from git@github.com:minrk/GrowlScript.git
test -z "$notify" && notify='echo'

root="http://build.chromium.org/buildbot/snapshots/chromium-rel-mac"
basename="chrome-mac"
zipfile="$basename.zip"
srcfile="$basename/Chromium.app"



cd $downloads || exit -1
echo "checking latest version:"
version=`curl -s $root/LATEST`
target="$basename-r$version.zip"

# echo $version
if [ ! -f $target ]; then
    echo "downloading Chromium-r$version"
    curl "$root/$version/$zipfile" -o "$target"  || exit -1
else
    $notify "Chromium already up to date at r$version"
    exit 0
fi

echo "unzipping..."
unzip -qu $target

echo "installing"...
osascript -e "tell application \"Finder\" to move (\"$downloads/$srcfile\" as POSIX file) to folder (\"$installdir\" as POSIX file) with replacing" || (echo "install may have failed" && exit -1)

echo "cleaning up..."
mv $target $target.t
for zip in $basename-r*.zip; do
    if [ $zip != "$basename-r*.zip" ]; then
        osascript -e "tell application \"Finder\" to move (\"$downloads/$zip\" as POSIX file) to trash"
    fi
done
mv $target.t $target

if [ removeafter = true ]; then
    rm -rf $basename
    rm $target
fi
$notify "Chromium updated to r$version"
