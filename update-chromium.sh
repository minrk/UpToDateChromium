#!/bin/sh

# configurable options:
removeafter=false
downloads="$HOME/Downloads"
installdir="/Applications"

notify=`which growl` # GrowlScript from git@github.com:minrk/GrowlScript.git
test -z "$notify" && notify='echo'

# end configurable options (probably)

root="http://build.chromium.org/buildbot/snapshots/chromium-rel-mac"
basename="chrome-mac"
zipfile="$basename.zip"
srcfile="$basename/Chromium.app"



cd $downloads || exit -1
echo "checking latest version: \\c"
version=`curl -s $root/LATEST`
echo $version
target="$basename-r$version.zip"

# echo $version
if [ ! -f $target ]; then
    $notify "downloading Chromium-r$version"
    curl "$root/$version/$zipfile" -o "$target"  || exit -1
else
    msg="Chromium already up to date at r$version"
    # There should not be a Chromium.app unless previous update failed:
    if [ ! -e $basename/Chromium.app ]; then
        $notify "Installed $msg"
        exit 0
    else # try installing
        $notify "Downloaded $msg, preparing to install..."
    fi
fi

echo "unzipping..."
unzip -qu $target

echo "installing..."
wasrunning=`osascript -e 'tell application "System Events" to (name of processes) contains "Chromium"'`
if [ $wasrunning = 'true' ]; then
    osascript -e 'tell application "Chromium" to activate' || ($notify "Chromium Update Cancelled" && kill $$)
    osascript -e 'tell application "Chromium" to display dialog "Restart Chromium for update?"' >/dev/null 2>/dev/null || ($notify "Chromium Update Cancelled" && kill $$)
    osascript -e 'tell application "Chromium" to quit' || ($notify "Chromium Update Cancelled" && kill $$)
    stillrunning=`osascript -e 'tell application "System Events" to (name of processes) contains "Chromium"'`
    while [ $stillrunning = 'true' ]; do
        sleep 0.25
        echo "waiting for Chromium to exit..."
        stillrunning=`osascript -e 'tell application "System Events" to (name of processes) contains "Chromium"'`
        echo $stillrunning
    done
fi
osascript -e "tell application \"Finder\" to move (\"$downloads/$srcfile\" as POSIX file) to folder (\"$installdir\" as POSIX file) with replacing">/dev/null || (echo "install may have failed" && kill $$)

echo "cleaning up..."
mv $target $target.t
for zip in $basename-r*.zip; do
    if [ $zip != "$basename-r*.zip" ]; then
        osascript -e "tell application \"Finder\" to move (\"$downloads/$zip\" as POSIX file) to trash">/dev/null
    fi
done
mv $target.t $target

if [ $removeafter = 'true' ]; then
    rm -rf $basename
    rm $target
fi
$notify "Chromium updated to r$version"

if [ $wasrunning = 'true' ]; then # restart Chromium
    osascript -e 'tell application "Chromium" to activate'
fi
