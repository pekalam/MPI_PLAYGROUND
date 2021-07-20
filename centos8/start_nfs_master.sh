#!/bin/bash

systemctl start rpcbind
systemctl start nfs-utils
systemctl start nfs-mountd
systemctl start nfs-server