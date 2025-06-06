# CVMFS server uftrace scripts
Scripts for generating a flamegraph svg for various CVMFS server commands, using uftrace and flamegraph. Repository un which the scripts are used must be owned by root.

## Prerequisites
- Uftrace must be installed and accessible on PATH, eiter via a package manager or by building from source.

## Usage
1. Build CVMFS with the tracing compiler flag
```sh
git clone https://github.com/cvmfs/cvmfs
mkdir cvmfs/build
cd cvmfs/build
cmake -DCMAKE_CXX_FLAGS=-pg ..
make
sudo make install
```
2. Create a CVMFS repository. Make sure it is owned by root (the default value)
```sh
cvmfs_server mkfs <repository name>
```
3. Run the script for the desired server command from this repository's root directory. Note that the specified repository *must* be owned by root.
```sh
sudo ./uftrace-<desired comand>.sh <repository name>
```
4. View the resulting svg in the `output` directory