#!/bin/bash

service rpcbind restart
mount -v -t nfs master:/cloud /cloud