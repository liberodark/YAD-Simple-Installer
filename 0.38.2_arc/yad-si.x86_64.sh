#!/bin/bash
#
# YAD Simple Installer 18.01.2019 by Хрюнделёк.
# https://rutracker.org/forum/profile.php?mode=viewprofile&u=17809259
# Thanks to Misko-2083 (https://github.com/Misko-2083) for the idea.
#
# YAD 0.38.2 (Yet Another Dialog) by Victor Ananjevsky.
# https://github.com/v1cont/yad
#
# FreeArc'Next 0.11 by Bulat Ziganshin.
# https://github.com/Bulat-Ziganshin/FA

# Application name
export appname="TinyKeep"

# Launchers icon
export icon="tinykeep_Data/Resources/UnityPlayer.png"

# Initial set
export dir="$(dirname "$(realpath "$0")")"
export fa="$dir"/fa.x86_64
export yad="$dir"/yad.x86_64

# User environment variables
[ -z "$XDG_CONFIG_HOME" ] && XDG_CONFIG_HOME="$HOME/.config"
. "$XDG_CONFIG_HOME/user-dirs.dirs"
[ -z "$XDG_DATA_HOME" ] && XDG_DATA_HOME="$HOME/.local/share"
[ -z "$XDG_DESKTOP_DIR" ] && XDG_DESKTOP_DIR="$HOME/Desktop"
export menu_dir="$XDG_DATA_HOME/applications"
export menu_launcher="$menu_dir/$appname.desktop"
export desktop_launcher="$XDG_DESKTOP_DIR/$appname.desktop"

# Stores basic process IDs
export main_proc_id="$(mktemp -u --tmpdir fpid.XXXXXXXX)"
export progress_pipe="$(mktemp -u --tmpdir ftd.XXXXXXXX)"
mkfifo "$progress_pipe"
export form_pipe="$(mktemp -u --tmpdir ftd2.XXXXXXXX)"
mkfifo "$form_pipe"
trap 'rm -f "$main_proc_id" "$progress_pipe" "$form_pipe"' "EXIT"
export key="$(($RANDOM * $$))"
export unpack='bash -c "install_app %1 %2 %3 %4"'

######################################
# Start the script in Russian locale #
######################################

if (locale | grep -e 'ru_RU'); then

function install_app
{

# Form fields are read in cycles, each cycle sets new values
# Disable all the form fields while unpacking
echo "@disabled@" > "$form_pipe"
echo "@disabled@" > "$form_pipe"
echo "@disabled@" > "$form_pipe"
echo "@disabled@" > "$form_pipe"

# Unpacking from the archive
"$fa" x "$dir"/archive.fa -o+ -dp"$1" >> "$progress_pipe" \
2>&1 >> "$progress_pipe" & echo "$!" >> "$main_proc_id"

# Wait here and it returns exit status "${?}"
# It's stderr redirected to /dev/null for prevent messages from the kill
wait "$(<$main_proc_id)" 2>/dev/null

if [ "$?" = "0" ]; then
	echo "#Установка завершена" >> "$progress_pipe"
	kill "$main_pid" 2>/dev/null
	>"$main_proc_id"
else
	echo "#Ошибка установки" >> "$progress_pipe"
	kill "$main_pid" 2>/dev/null
	>"$main_proc_id"
fi

# Create launchers in the applications menu and/or on the desktop
if [ "$2" = "TRUE" ]; then
	[ ! -d "$menu_dir" ] && mkdir -p "$menu_dir"
	cat << EOF > "$menu_launcher"
[Desktop Entry]
Name=$appname
Exec="$1/$appname/run.sh"
Icon=$1/$appname/$icon
Type=Application
Categories=Game;
StartupNotify=true
Comment=Start $appname
Comment[ru_RU]=Запустить $appname
EOF
	chmod +x "$menu_launcher"
fi

if [ "$3" = "TRUE" ]; then
	cat << EOF > "$desktop_launcher"
[Desktop Entry]
Name=$appname
Exec="$1/$appname/run.sh"
Icon=$1/$appname/$icon
Type=Application
Categories=Game;
StartupNotify=true
Comment=Start $appname
Comment[ru_RU]=Запустить $appname
EOF
	chmod +x "$desktop_launcher"
fi
}

export -f install_app

function get_pid_and_kill
{
sure_command='"$yad" --title=" " --width=1 \
	--text="Отменить установку?" \
	--text-align=center --on-top --center \
	--window-icon="system-software-install" \
	--button="Да!gtk-yes:0" --button="Нет!gtk-no:1"'
sure_command_pid="$(ps -eo pid,cmd | grep -F "$sure_command" | grep -v \
"grep" | awk '{ print $1 }')"

if [ -s "$main_proc_id" ] && [ "$sure_command_pid" = "" ] && \
	"$yad" --title=" " --width=1 \
	--text="Отменить установку?" \
	--text-align=center	--on-top --center \
	--window-icon="system-software-install" \
	--button="Да!gtk-yes:0" --button="Нет!gtk-no:1"; then
	if [ -s "$main_proc_id" ]; then
		bckupid="$(<$main_proc_id)"
		>"$main_proc_id"
		kill "$bckupid" 2>/dev/null
	fi

# Special YAD variable "$YAD_PID" stores the main window PID
# Killing that PID closes the window
	[ "$1" = "CLOSE" ] && kill -s SIGUSR2 "$YAD_PID"
elif [ ! -s "$main_proc_id" ]; then
	[ "$1" = "CLOSE" ] && kill -s SIGUSR2 "$YAD_PID"
fi
}

export -f get_pid_and_kill

exec 3<> "$progress_pipe"
exec 4<> "$form_pipe"

"$yad" --plug="$key" --tabnum=1 --form \
--field=" Выберите путь для установки::DIR" \
--image="$dir"/header.jpg --image-on-top \
--field=" Создать значок запуска в меню приложений:CHK" \
--field=" Создать значок запуска на рабочем столе:CHK" \
--field=" Начать установку!system-software-install:fbtn" \
--cycle-read <&4 &

# Initial cycle that sets the form field values
echo "$HOME" > "$form_pipe"		# default directory
echo "TRUE" > "$form_pipe"		# default first checkbox value
echo "FALSE" > "$form_pipe"		# default second checkbox value
echo "$unpack &" > "$form_pipe"	# progress bar value

"$yad" --plug="$key" --tabnum=2 --progress <&3 &

"$yad" --paned --key="$key" --buttons-layout=center \
--button=" Выйти!gtk-quit":'bash -c "get_pid_and_kill CLOSE" 2>/dev/null' \
--title="$appname: YAD Simple Installer" \
--window-icon="system-software-install" --fixed \
--center --no-escape --undecorated & main_pid="$!"

# Redirecting kill output from get_pid_and_kill function to /dev/null
wait "$main_pid" 2>/dev/null

exec 3>&-
exec 4>&-
exit 0
fi

#######################################################
# Start the script in English for non-Russian locales #
#######################################################

function install_app
{

# Form fields are read in cycles, each cycle sets new values
# Disable all the form fields while unpacking
echo "@disabled@" > "$form_pipe"
echo "@disabled@" > "$form_pipe"
echo "@disabled@" > "$form_pipe"
echo "@disabled@" > "$form_pipe"

# Unpacking from the archive
"$fa" x "$dir"/archive.fa -o+ -dp"$1" >> "$progress_pipe" \
2>&1 >> "$progress_pipe" & echo "$!" >> "$main_proc_id"

# Wait here and it returns exit status "${?}"
# It's stderr redirected to /dev/null for prevent messages from the kill
wait "$(<$main_proc_id)" 2>/dev/null

if [ "$?" = "0" ]; then
	echo "#Installation completed" >> "$progress_pipe"
	kill "$main_pid" 2>/dev/null
	>"$main_proc_id"
else
	echo "#Installation error" >> "$progress_pipe"
	kill "$main_pid" 2>/dev/null
	>"$main_proc_id"
fi

# Create launchers in the applications menu and/or on the desktop
if [ "$2" = "TRUE" ]; then
	[ ! -d "$menu_dir" ] && mkdir -p "$menu_dir"
	cat << EOF > "$menu_launcher"
[Desktop Entry]
Name=$appname
Exec="$1/$appname/run.sh"
Icon=$1/$appname/$icon
Type=Application
Categories=Game;
StartupNotify=true
Comment=Start $appname
Comment[ru_RU]=Запустить $appname
EOF
	chmod +x "$menu_launcher"
fi

if [ "$3" = "TRUE" ]; then
	cat << EOF > "$desktop_launcher"
[Desktop Entry]
Name=$appname
Exec="$1/$appname/run.sh"
Icon=$1/$appname/$icon
Type=Application
Categories=Game;
StartupNotify=true
Comment=Start $appname
Comment[ru_RU]=Запустить $appname
EOF
	chmod +x "$desktop_launcher"
fi
}

export -f install_app

function get_pid_and_kill
{
sure_command='"$yad" --title=" " --width=1 \
	--text="Are you sure you want to cancel?" \
	--text-align=center --on-top --center \
	--window-icon="system-software-install" \
	--button="gtk-yes:0" --button="gtk-no:1"'
sure_command_pid="$(ps -eo pid,cmd | grep -F "$sure_command" | grep -v \
"grep" | awk '{ print $1 }')"

if [ -s "$main_proc_id" ] && [ "$sure_command_pid" = "" ] && \
	"$yad" --title=" " --width=1 \
	--text="Are you sure you want to cancel?" \
	--text-align=center	--on-top --center \
	--window-icon="system-software-install" \
	--button="gtk-yes:0" --button="gtk-no:1"; then
	if [ -s "$main_proc_id" ]; then
		bckupid="$(<$main_proc_id)"
		>"$main_proc_id"
		kill "$bckupid" 2>/dev/null
	fi

# Special YAD variable "$YAD_PID" stores the main window PID
# Killing that PID closes the window
	[ "$1" = "CLOSE" ] && kill -s SIGUSR2 "$YAD_PID"
elif [ ! -s "$main_proc_id" ]; then
	[ "$1" = "CLOSE" ] && kill -s SIGUSR2 "$YAD_PID"
fi
}

export -f get_pid_and_kill

exec 3<> "$progress_pipe"
exec 4<> "$form_pipe"

"$yad" --plug="$key" --tabnum=1 --form \
--field=" Select the destination path::DIR" \
--image="$dir"/header.jpg --image-on-top \
--field=" Create a launcher in the applications menu:CHK" \
--field=" Create a launcher on the desktop:CHK" \
--field=" Begin Installation!system-software-install:fbtn" \
--cycle-read <&4 &

# Initial cycle that sets the form field values
echo "$HOME" > "$form_pipe"		# default directory
echo "TRUE" > "$form_pipe"		# default first checkbox value
echo "FALSE" > "$form_pipe"		# default second checkbox value
echo "$unpack &" > "$form_pipe"	# progress bar value

"$yad" --plug="$key" --tabnum=2 --progress <&3 &

"$yad" --paned --key="$key" --buttons-layout=center \
--button=" Quit!gtk-quit":'bash -c "get_pid_and_kill CLOSE" 2>/dev/null' \
--title="$appname: YAD Simple Installer" \
--window-icon="system-software-install" --fixed \
--center --no-escape --undecorated & main_pid="$!"

# Redirecting kill output from get_pid_and_kill function to /dev/null
wait "$main_pid" 2>/dev/null

exec 3>&-
exec 4>&-
exit 0
