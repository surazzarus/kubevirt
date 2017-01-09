#!/usr/bin/bash

set -xe

fatal() { echo "FATAL: $@" >&2 ; exit 2 ; }
[[ -f /host/var/run/libvirtd.pid ]] && fatal "libvirtd seems to be running on the host"

# HACK
# Use hosts's /dev to see new devices and allow macvtap
mkdir /dev.container && {
  mount --make-rprivate --rbind /dev /dev.container

  mount --rbind /host/dev /dev

  # Keep some devices from the containerinal /dev
  keep() { mount --rbind /dev.container/$1 /dev/$1 ; }
  keep shm
  keep mqueue
  # Keep ptmx/pts for pty creation
  keep pts
  mount --rbind /dev/pts/ptmx /dev/ptmx
  # Use the container /dev/kvm if available
  [[ -e /dev.container/kvm ]] && keep kvm
}

mount --rbind /host/sys /sys

/usr/sbin/virtlogd &
/usr/sbin/libvirtd -l
