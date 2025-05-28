#!/bin/bash

FLAMEGRAPH_FILE="flamegraph_dump.txt"

usage() {
	echo "Usage: $0 [-o output file] repository_name"
	echo "Make sure CVMFS is built with the -pg compiler flag"
	echo "flamegraph.pl must be placed in the working directory (see https://github.com/brendangregg/FlameGraph/blob/master/flamegraph.pl)"
	exit 1
}

# Check options
while getopts ":o:h" opt; do
	case "$opt" in
		o)
			GENERATE_TXT=1	
			OUTPUT_FILE="$OPTARG" ;;
		h)
			usage ;;	
		?) 
			echo "Invalid option";
			usage ;;
	esac
done

shift $((OPTIND -1))

if [ $# -lt 1 ]; then
	echo "Missing repository name"
	usage
fi

REPO_NAME="$1"
TAR_DIR="tarDir"
TAR_NAME="output.tar"

# Create tar file
mkdir -p numbers
mkdir -p numbers/2/4/6/8
mkdir -p numbers/1/3/5/7/9
echo "these are even" > numbers/2/4/6/8/even
echo "these are odd" > numbers/1/3/5/7/9/odd
tar -cf $TAR_NAME numbers 

# Record ingest command and clean up
uftrace record --force -e cvmfs_server ingest -t $TAR_NAME -b tarDir $REPO_NAME
cvmfs_server transaction $REPO_NAME
rm -rf /cvmfs/$REPO_NAME/$TAR_DIR
cvmfs_server publish $REPO_NAME

UFTRACE_OPTIONS="hide='std::*'"

# Generate txt output
if [ "${GENERATE_TXT:-0}" -eq 1 ]; then
	uftrace replay $UFTRACE_OPTIONS > $OUTPUT_FILE
fi

# Generate flamegraph
uftrace dump --flame-graph $UFTRACE_OPTIONS > $FLAMEGRAPH_FILE
./flamegraph.pl $FLAMEGRAPH_FILE > graph_ingest.svg

# Clean up files
rm -rf uftrace.data*
rm $FLAMEGRAPH_FILE
rm gmon.out
rm $TAR_NAME
rm -rf numbers
