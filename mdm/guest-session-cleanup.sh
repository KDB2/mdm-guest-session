#!/bin/sh -e
# Requires guest account name as $1.

USER="$1"

PWENT=`getent passwd "$USER"` || {
    echo "Error: invalid user $USER"
    exit 1
}
UID=`echo "$PWENT" | cut -f3 -d:`
HOME=`echo "$PWENT" | cut -f6 -d:`

if [ "$UID" -ge 500 ]; then
    echo "Error: user $USER is not a system user."
    exit 1
fi

if [ "${HOME}" = "${HOME#/tmp/}" ]; then
    echo "Error: home directory $HOME is not in /tmp/."
    exit 1
fi

# kill all remaining processes
while ps h -u "$USER" >/dev/null; do 
    killall -9 -u "$USER" || true
    sleep 0.2; 
done

umount "$HOME" || umount -l "$HOME" || true
rm -rf "$HOME"

# remove leftovers in /tmp
find /tmp -mindepth 1 -maxdepth 1 -uid "$UID" -print0 | xargs -0 rm -rf || true

# remove mdm cache files
find /var/cache/mdm -mindepth 1 -maxdepth 1 -uid "$UID" -print0 | xargs -0 rm -rf || true

deluser --system "$USER"

