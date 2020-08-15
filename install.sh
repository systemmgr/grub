#!/usr/bin/env bash

SCRIPTNAME="$(basename $0)"
SCRIPTDIR="$(dirname "${BASH_SOURCE[0]}")"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author      : Jason
# @Contact     : casjaysdev@casjay.net
# @File        : install.sh
# @Created     : Mon, Dec 31, 2019, 00:00 EST
# @License     : WTFPL
# @Copyright   : Copyright (c) CasjaysDev
# @Description : installer script for templates
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

SCRIPTSFUNCTURL="${SCRIPTSFUNCTURL:-https://github.com/casjay-dotfiles/scripts/raw/master/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSFUNCTFILE:-app-installer.bash}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -f "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE" ]; then
    . "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE"
elif [ -f "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE" ]; then
    . "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
else
    mkdir -p "/tmp/CasjaysDev/functions"
    curl -LSs "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "/tmp/CasjaysDev/functions/$SCRIPTSFUNCTFILE" || exit 1
    . "/tmp/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
fi

grub() { cmd_exists grub || cmd_exists grub2; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Requires root - no point in continuing

sudoreq # sudo required
#sudorun  # sudo optional

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Make sure the scripts repo is installed

scripts_check

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Defaults

APPNAME="grub"
PLUGNAME=""

# USER
if [[ $EUID -ne 0 ]]; then
    BIN="$HOME/.local/bin"
    CONF="$HOME/.config"
    SHARE="$HOME/.local/share"
    LOGDIR="$HOME/.local/logs"
    BACKUPDIR="${BACKUPS:-$HOME/.local/backups/dotfiles}"
    COMPDIR="${BASH_COMPLETION_USER_DIR:-$HOME/.local/share/bash_completion.d}"

# SYSTEM
else
    BIN="/usr/local/bin"
    CONF="/usr/local/etc"
    SHARE="/usr/local/share/CasjaysDev"
    LOGDIR="/usr/local/log"
    BACKUPDIR="/usr/local/share/backups/dotfiles"
    COMPDIR="/etc/bash_completion.d"

fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# git repos

REPO="${THEMEMGRREPO:-https://github.com/thememgr}"
REPORAW="$REPO/$APPNAME/raw"
PLUGINREPO=""

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Version

APPVERSION="$(curl -LSs $REPORAW/master/version.txt)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set options

APPDIR="$CONF/$APPNAME"
PLUGDIR="$CONF/$APPNAME/$PLUGNAME"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$1" = "--cron" ]; then
    crontab_add "$@"
    exit
fi
if [ "$1" = "--help" ]; then
    xdg-open "$REPO/$APPNAME"
    exit
fi
if [ "$1" = "--update" ]; then
    versioncheck
    exit
fi
if [ "$1" = "--version" ] && [ -f "$APPDIR/version.txt" ]; then
    cat "$APPDIR/version.txt" | grep -v "#" | tail -n 1
    exit
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# prerequisites

APP=""
PKG=""
PIP=""
MISSING=""
PIPMISSING=""

# - - - - - - - - - - - - - - -

# install required packages
cmd_exists grub || pkmgr required grub

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Ensure directories exist

mkd "$SHARE"
mkd "$LOGDIR"
mkd "$COMPDIR"
mkd "$BACKUPDIR"
mkd "$CONF/CasjaysDev/thememgr"
chmod 777 "$SHARE"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Main progam

if [ -d "$APPDIR/.git" ]; then
    execute \
        "git_update $APPDIR" \
        "Updating $APPNAME configurations"
else
    execute \
        "backupapp && \
         git_clone -q $REPO/$APPNAME $APPDIR" \
        "Installing $APPNAME configurations"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Plugins

if [ "$PLUGNAME" != "" ]; then
    if [ -d "$PLUGDIR"/.git ]; then
        execute \
            "git_update $PLUGDIR" \
            "Updating $PLUGNAME"
    else
        execute \
            "git_clone $PLUGINREPO $PLUGDIR" \
            "Installing $PLUGNAME"
    fi
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# run post install scripts

run_postinst() {
    if [ ! -f "$APPDIR/.inst" ] && [ ! -L /boot/grub/themes/default ] && cmd_exists grub-mkconfig &&
        [ -f /boot/grub/grub.cfg ] && [ -f /etc/default/grub ]; then
        GRUB="/usr/sbin/grub-mkconfig"
        mkd /boot/grub/themes
        cp_rf /etc/default/grub /etc/default/grub.bak
        cp_rf $APPDIR/themes/* /boot/grub/themes
        cp_rf $APPDIR/grub /etc/default/grub
        ln_sf /boot/grub/themes/poly-dark /boot/grub/themes/default
        sed -i 's|^\(GRUB_TERMINAL\w*=.*\)|#\1|' /etc/default/grub
        sed -i 's|grubdir|grub|g' /etc/default/grub
        ${GRUB} -o /boot/grub/grub.cfg

    elif [ ! -f $APPDIR/.inst ] && [ ! -L /boot/grub2/themes/default ] && cmd_exists grub-mkconfig &&
        [ -f /boot/grub2/grub.cfg ] && [ -f /etc/default/grub ]; then
        GRUB="/usr/sbin/grub2-mkconfig"
        mkd /boot/grub2/themes
        cp_rf /etc/default/grub /etc/default/grub.bak
        cp_rf $APPDIR/themes/* /boot/grub2/themes
        cp_rf $APPDIR/grub /etc/default/grub
        ln_sf /boot/grub2/themes/poly-dark /boot/grub2/themes/default
        sed -i 's|^\(GRUB_TERMINAL\w*=.*\)|#\1|' /etc/default/grub
        sed -i 's|grubdir|grub2|g' /etc/default/grub
        ${GRUB} -o /boot/grub2/grub.cfg
    fi
    touch $APPDIR/.inst
}

execute \
    "run_postinst" \
    "Running post install scripts"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# create version file

if [ ! -f "$CONF/CasjaysDev/thememgr/$APPNAME" ] && [ -f "$APPDIR/version.txt" ]; then
    ln_sf "$APPDIR/install.sh" "$CONF/CasjaysDev/thememgr/$APPNAME"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# exit
if [ ! -z "$EXIT" ]; then exit "$EXIT"; fi

# end
# vim: set expandtab ts=2 noai
