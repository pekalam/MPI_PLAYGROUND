#!/bin/bash

systemctl start rpcbind
systemctl start nfs-utils
systemctl start nfs-mountd
mount -v master:/cloud /cloud