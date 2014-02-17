#!/bin/sh -e
# Setup user and temporary home directory for guest session.
# If this succeeds, this script needs to print the username as last line to
# stdout.

USER=guest

# if $USER already exists, it must be a locked system account with no existing
# home directory
if PWSTAT=`passwd -S "$USER"` 2>/dev/null; then
    if [ "`echo \"$PWSTAT\" | cut -f2 -d\ `" != "L" ]; then
        echo "User account $USER already exists and is not locked"
        exit 1
    fi
    PWENT=`getent passwd "$USER"` || {
        echo "getent passwd $USER failed"
        exit 1
    }
    GUEST_UID=`echo "$PWENT" | cut -f3 -d:`
    if [ "$GUEST_UID" -ge 500 ]; then
        echo "For some reason Account $USER is not a system user"
        exit 1
    fi
    HOME=`echo "$PWENT" | cut -f6 -d:`
    if [ "$HOME" != / ] && [ "${HOME#/tmp}" = "$HOME" ] && [ -d "$HOME" ]; then
        echo "Home directory of $USER already exists, so stop littering"
        exit 1
    fi
else
    # does not exist, so create it
    adduser --system --no-create-home --home / --gecos "Guest" --group --shell /bin/bash $USER || {
        umount "$HOME"
        rm -rf "$HOME"
        exit 1
    }
fi

# create temporary home directory
HOME=`mktemp -td guest_home.XXXXXX`
mount -t tmpfs -o mode=700 none "$HOME" || { rm -rf "$HOME"; exit 1; }
chown $USER:$USER "$HOME"
cp -rT /etc/skel/ "$HOME"
chown -R $USER:$USER "$HOME"
usermod -d "$HOME" "$USER"

#
# setup session
#

#Lagacy crap
# disable screensaver, to avoid locking guest out of itself (no password)
#su $USER <<EOF
#gconftool-2 --set --type bool /desktop/gnome/lockdown/disable_lock_screen True
#EOF

# disable some services that are unnecessary for the guest session
mkdir --parents "$HOME"/.config/autostart
cd /etc/xdg/autostart/
services="update-notifier.desktop user-dirs-update-gtk.desktop mintUpdate.desktop mintUpload.desktop"
for service in $services
do
    if [ -e /etc/xdg/autostart/"$service" ] ; then
        cp "$service" "$HOME"/.config/autostart
        echo "X-GNOME-Autostart-enabled=false" >> "$HOME"/.config/autostart/"$service"
    fi
done

chown -R $USER:$USER "$HOME"

# force restricted guest session (dmrc file owned by root) and launch
# restricted session # corresponding to the current one ($1)
mkdir --parents /var/cache/mdm/"$USER"
dmrc='[Desktop]\nSession=guest-restricted'
if [ -f "/usr/share/xsessions/${1}-guest-restricted.desktop" ] ; then
    dmrc="[Desktop]\nSession=${1}-guest-restricted"
fi
/bin/echo -e "$dmrc" > /var/cache/mdm/"$USER"/dmrc

echo #TODO: bug workaround, mdm expects to find a newline

# report user name to mdm
echo "$USER"
