#!/bin/bash

{
    set -e

    echo "Compiling with mpiCC"
    mpiCC -o /cloud/hello-world.exe /cloud/hello-world.cpp

    echo "Running on $1 proccessors"
    mpirun -machinefile /cloud/machinefile -np $1 /cloud/hello-world.exe
}

rm /cloud/hello-world.exe