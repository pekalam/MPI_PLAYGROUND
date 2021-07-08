#!/bin/bash

set -e

echo "/cloud *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
