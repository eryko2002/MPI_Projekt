#!/bin/bash

wget -qO- https://github.com/MiniZinc/MiniZincIDE/releases/download/2.9.4/MiniZincIDE-2.9.4-bundle-linux-x86_64.tgz | tar -xz
cd /home/eglab/Desktop/mgr-repo/solver/MiniZincIDE-2.9.4-bundle-linux-x86_64
export PATH=$PWD/bin:$PATH
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH
export QT_PLUGIN_PATH=$PWD/plugins:$QT_PLUGIN_PATH
./MiniZincIDE.sh 
minizinc --version
