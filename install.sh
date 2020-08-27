#!/usr/bin/env bash

APPNAME="$(basename $0)"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author          : Jason
# @Contact         : casjaysdev@casjay.net
# @File            : install.sh
# @Created         : Wed, Aug 09, 2020, 02:00 EST
# @License         : WTFPL
# @Copyright       : Copyright (c) CasjaysDev
# @Description     : installer script for grub
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

SCRIPTSFUNCTURL="${SCRIPTSAPPFUNCTURL:-https://github.com/dfmgr/installer/raw/master/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSAPPFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSAPPFUNCTFILE:-app-installer.bash}"

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

grub() { cmd_exists grub2 && APPINSTNAME=grub2 || cmd_exists grub && APPINSTNAME=grub ;}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Make sure the scripts repo is installed

scripts_check

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Defaults

APPNAME="grub"
PLUGNAME=""

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# git repos

PLUGINREPO=""

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# if installing system wide - change to system_installdirs

systemmgr_installer

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Version

APPVERSION="$(curl -LSs ${SYSTEMMGRREPO:-https://github.com/systemmgr}/$APPNAME/raw/master/version.txt)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set options

APPDIR="$HOMEDIR/$APPNAME"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Script options IE: --help

show_optvars "$@"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Requires root - no point in continuing

sudoreq # sudo required
#sudorun  # sudo optional

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

APP="$APPINSTNAME "
APP+=""
PERL=""
PYTH=""
PIPS=""
CPAN=""
GEMS=""

# install packages - useful for package that have the same name on all oses
install_packages $APP

# install required packages using file
install_required $APP

# check for perl modules and install using system package manager
install_perl $PERL

# check for python modules and install using system package manager
install_python $PYTH

# check for pip binaries and install using python package manager
install_pip $PIPS

# check for cpan binaries and install using perl package manager
install_cpan $CPAN

# check for ruby binaries and install using ruby package manager
install_gem $GEMS

# Other dependencies
dotfilesreq
dotfilesreqadmin

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Ensure directories exist

ensure_dirs
ensure_perms

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

# run post install scripts

run_postinst() {
    run_postinst_systemgr
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

install_systemmgr_version

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# exit
run_exit

# end
