#!/usr/bin/env bash

# Set these parameters to your Red Hat Customer Portal
# (https://access.redhat.com) user name and the desired pool ID,
# respectively.  This should be a valid pool ID that includes the
# following repositories:
#
#     rhel-7-server-rpms
#     rhel-7-server-extras-rpms
#     rhel-7-server-optional-rpms
#
# If you're a Red Hat employee, the script will try to automatically
# discover the pool ID.
#
RHSM_USER="YOUR_RHSM_USER_NAME"
POOL=

subscription-manager unregister
echo "Enter your RHSM password when prompted"
subscription-manager register --username $RHSM_USER || exit 1

# automatically determine pool id if missing
if [[ -z "$POOL" ]]
then
  POOL=$(subscription-manager list --available --all | \
    grep 'Subscription Name\|Pool ID\|System Type' | \
    grep -A2 Employee | grep -B2 Virtual | grep 'Pool ID' | \
    awk '{print $3; exit}')
fi

if [[ -z "$POOL" ]]
then
  echo
  echo "No valid pool id found"
  exit 1
fi

# subscribe to the necessary repositories
subscription-manager attach --pool=${POOL}
subscription-manager repos --disable='*'
subscription-manager repos \
    --enable=rhel-7-server-rpms \
    --enable=rhel-7-server-optional-rpms \
    --enable=rhel-7-server-extras-rpms

yum -y update
yum -y install buildah git golang yum-utils
yum -y clean all

# enable user namespace remapping
BOOT_VMLINUZ=$(find /boot -type f -name 'vmlinuz*x86_64' | tail -1)
grubby --remove-args="user_namespace.enable=1" --update-kernel=$BOOT_VMLINUZ
grubby --args="namespace.unpriv_enable=1" --update-kernel=$BOOT_VMLINUZ
echo "user.max_user_namespaces=1507" >> /etc/sysctl.conf

echo 'root:100000:65536' >> /etc/subuid
echo 'root:100000:65536' >> /etc/subgid

reboot

