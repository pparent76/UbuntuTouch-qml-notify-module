#!/bin/sh

################################################################################
#                    Utils functions
################################################################################
cp_safe() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$dest" ]; then
        cp -v "$src" "$dest"
        echo "[OK] File created: $dest"
    else
        echo "[SKIP] File already exists in project: $dest"
    fi
}

cp_dir_safe() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$dest" ]; then
        cp -r  "$src" "$dest"
        echo "[OK] Folder created: $dest"
    else
        echo "[SKIP] Folder already exists in project: $dest"
    fi
}

write_if_not_present () {
    local str="$1"
    local file="$2"
    cat $file | grep "$str" >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        echo "[OK] Adding missing line $str \n"
        echo "$str" >> $file
    fi
}


check_if_file_exist () {
    local file="$1"
    local defaultRes="$2"    
    if [ -e "$file" ]; then
        echo "[WARNING] File allready exists: $file" 
        return 1;
    else
        return $defaultRes
    fi
}


################################################################################
#               Get application id and title
################################################################################
folder=$1
appid=$(jq -r '.name' $folder/manifest.json)
title=$(jq -r '.title' $folder/manifest.json)
echo ""
echo "->Geting project informations"
echo "Configuring project for Application $appid (hook: $title)"

################################################################################
#               Check for signs of allready installed app
################################################################################
exist="0"

check_if_file_exist $folder/$title-push.apparmor $exist; exist=$?;
check_if_file_exist $folder/$title-push-helper.json $exist; exist=$?;
check_if_file_exist $folder/push-apparmor.json $exist; exist=$?;
check_if_file_exist $folder/pushexec $exist; exist=$?;
check_if_file_exist $folder/qml-notify-module $exist; exist=$?;

if jq -e '.hooks.push' $folder/manifest.json >/dev/null; then
    echo "[WARNING] 'push' hook already exists in $folder/manifest.json"
    exist=1
fi

if [ -e "$folder/CMakeLists.txt" ]; then
cat $folder/CMakeLists.txt | grep "add_subdirectory(qml-notify-module)" >/dev/null
    if [ "$?" -eq "0" ]; then
        echo "[WARNING] qml-notify-module allready present in CMakeLists.txt"
        exist=1
    fi
cat $folder/CMakeLists.txt | grep "$title-push.apparmor" >/dev/null
    if [ "$?" -eq "0" ]; then
        echo "[WARNING] $title-push.apparmor allready present in CMakeLists.txt"
        exist=1
    fi  
cat $folder/CMakeLists.txt | grep "$title-push-helper.json" >/dev/null
    if [ "$?" -eq "0" ]; then
        echo "[WARNING] $title-push-helper.json allready present in CMakeLists.txt"
        exist=1
    fi    
cat $folder/CMakeLists.txt | grep "push-apparmor.json" >/dev/null
    if [ "$?" -eq "0" ]; then
        echo "[WARNING] push-apparmor.json allready present in CMakeLists.txt"
        exist=1
    fi  
cat $folder/CMakeLists.txt | grep "pushexec" >/dev/null
    if [ "$?" -eq "0" ]; then
        echo "[WARNING] pushexec allready present in CMakeLists.txt"
        exist=1
    fi         
fi

if [ "$exist" -ne "0" ]; then
 echo "Project show signs of allready installed module, or push notification system exiting..."
 exit 1;
fi

################################################################################
#               Copy all the required files
################################################################################
echo ""
echo "->Copying necessary files to folder....."
cp_safe project_conf_files/icon.png  $folder/icon.png
cp_safe project_conf_files/PROJECT-push.apparmor  $folder/$title-push.apparmor
cp_safe project_conf_files/PROJECT-push-helper.json  $folder/$title-push-helper.json
cp_safe project_conf_files/push-apparmor.json $folder/push-apparmor.json
cp_safe project_conf_files/pushexec $folder/pushexec
cp_dir_safe module $folder/qml-notify-module

################################################################################
#       Reconfiguring app profile (manifest.json, app.apparmor and app.desktop)
################################################################################
echo ""
echo "->Reconfiguring app profile....."

#Apparmor Reconfiguration (add push-notification-client)
if jq -e ".policy_groups | index(\"push-notification-client\")" $folder/$title.apparmor >/dev/null; then
    echo "[SKIP] push-notification-client already present in $folder/$title.apparmor"
else
    tmp=$(mktemp)
    jq ".policy_groups += [\"push-notification-client\"]" $folder/$title.apparmor > "$tmp" && mv "$tmp" $folder/$title.apparmor
    echo "[OK] Added push-notification-client to policy_groups in $folder/$title.apparmor"
fi

#Manifest.json create push hook if does not exist
if jq -e '.hooks.push' $folder/manifest.json >/dev/null; then
    echo "[SKIP] 'push' hook already exists under hooks.whatsweb"
else
    tmp=$(mktemp)
    jq ".hooks.push = {
            \"apparmor\": \"$title-push.apparmor\",
            \"push-helper\": \"$title-push-helper.json\"
        }" $folder/manifest.json > "$tmp" && mv "$tmp" $folder/manifest.json
    echo "[OK] Added 'push' hook under hooks.whatsweb in $folder/manifest.json"
fi

#app.desktop Reconfiguration to include qml plugins : qmlscene -I qml-plugins
cat $folder/$title.desktop | grep qmlscene >/dev/null 2>&1
if [ "$?" -eq "0" ]; then
    echo "$title.desktop is based on qmlscene: we need to include qml-plugins/"
    cat $folder/$title.desktop | grep qmlscene | grep "qml-plugins/" >/dev/null 2>&1
    if [ "$?" -eq "0" ]; then
        echo "[SKIP] $title.desktop already contains a reference to qml-plugins/"
    else
        cat $folder/$title.desktop | grep "qmlscene %u"
        if [ "$?" -eq "0" ]; then
            sed -i "s/qmlscene \%u/qmlscene %u -I qml-plugins\//g" $folder/$title.desktop
            echo "[OK] $title.desktop reconfigured to include qml-plugin"
        else
            sed -i "s/qmlscene/qmlscene -I qml-plugins\//g" $folder/$title.desktop
            echo "[OK] $title.desktop reconfigured to include qml-plugin"
        fi
    fi
else
    echo "[SKIP]$title.desktop is NOT based on qmlscene"
fi

################################################################################
#                    Handle CMakefiles.txt
################################################################################
echo ""
echo "->Handling CMakeLists.txt....."
if [ ! -e "$folder/CMakeLists.txt" ]; then
    echo "CMakefiles.txt not existing creating it"
    cp_safe project_conf_files/CMakeLists.txt.in $folder/CMakeLists.txt
    sed -i "s/TPL_PROJECT_NAME/$title/g" $folder/CMakeLists.txt
    echo "[OK] CMakeLists.txt generated"
    cp_safe project_conf_files/clickable.yaml $folder/clickable.yaml  
    for f in $(find $folder -maxdepth 1 -type f ! -name ".*"); do
        filebase=$(basename $f)
        if [ "$filebase" != "README.md" ]&& [ "$filebase" != "clickable.yaml" ]&& [ "$filebase" != "pushexec" ]&& [ "$filebase" != "pushexec" ]&& [ "$filebase" != "CMakeLists.txt" ]; then
            write_if_not_present   "install(FILES $(basename $f) DESTINATION \${CMAKE_INSTALL_PREFIX})" $folder/CMakeLists.txt
        fi
    done
else
    echo "Checking cmakefiles"
    
    for f in icon.png $title-push.apparmor $title-push-helper.json push-apparmor.json ; do
        write_if_not_present   "install(FILES $f DESTINATION \${CMAKE_INSTALL_PREFIX})" $folder/CMakeLists.txt   
    done
    write_if_not_present   "install(PROGRAMS pushexec DESTINATION ${CMAKE_INSTALL_PREFIX})" $folder/CMakeLists.txt 
    write_if_not_present   "add_subdirectory(qml-notify-module)" $folder/CMakeLists.txt
    
fi

################################################################################
#                    SHOW example QML code
################################################################################

echo ""
echo "-> You can now add to your QML code:"

echo ""
echo "    NotificationHelper {"
echo "       id: helper"
echo "       push_app_id:$appid_$title"
echo "    }"
echo ""
echo "And call helper.send(\"Hello world\") Where you need it"

