#!/bin/bash

exportfs -a
service rpcbind restart
service nfs-kernel-server restart