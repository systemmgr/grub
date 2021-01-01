#!/usr/bin/env bash

APPNAME="grub"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author          : Jason
# @Contact         : casjaysdev@casjay.net
# @File            : install.sh
# @Created         : Fr, Aug 28, 2020, 00:00 EST
# @License         : WTFPL
# @Copyright       : Copyright (c) CasjaysDev
# @Description     : installer script for grub
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

SCRIPTSFUNCTURL="${SCRIPTSAPPFUNCTURL:-https://github.com/casjay-dotfiles/scripts/raw/master/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSAPPFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSAPPFUNCTFILE:-app-installer.bash}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -f "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE"
elif [ -f "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
else
  curl -LSs "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "/tmp/$SCRIPTSFUNCTFILE" || exit 1
  . "/tmp/$SCRIPTSFUNCTFILE"
fi

grub() { cmd_exists grub2 && APPINSTNAME=grub2 || cmd_exists grub && APPINSTNAME=grub; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
system_installdirs

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Make sure the scripts repo is installed

scripts_check

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Defaults
APPNAME="${APPNAME:-grub}"
APPDIR="/usr/local/etc/$APPNAME"
REPO="${SYSTEMMGRREPO:-https://github.com/systemmgr}/${APPNAME}"
REPORAW="${REPORAW:-$REPO/raw}"
APPVERSION="$(curl -LSs $REPORAW/master/version.txt)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# dfmgr_install fontmgr_install systemmgr_install pkmgr_install systemmgr_install thememgr_install wallpapermgr_install

systemmgr_install

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Script options IE: --help

show_optvars "$@"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# end with a space

APP="$APPNAME "

# install packages - useful for package that have the same name on all oses
install_packages $APP

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

# exit on fail
failexitcode

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# run post install scripts

run_postinst() {
  systemmgr_run_postinst
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

systemmgr_install_version

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# exit
run_exit

# end
