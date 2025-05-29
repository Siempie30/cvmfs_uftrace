#!/bin/bash

FLAMEGRAPH_FILE="flamegraph_dump.txt"

usage() {
	echo "Usage: $0 [-o output file] [-h]"
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

# Record transaction command and abort
uftrace record --force /usr/bin/cvmfs_server transaction
cvmfs_server abort --force

UFTRACE_OPTIONS="hide='std::*'"

# Generate txt output
if [ "${GENERATE_TXT:-0}" -eq 1 ]; then
	uftrace replay $UFTRACE_OPTIONS > $OUTPUT_FILE
fi

# Generate flamegraph
uftrace dump --flame-graph $UFTRACE_OPTIONS > $FLAMEGRAPH_FILE
./flamegraph.pl $FLAMEGRAPH_FILE > flamegraph_transaction.svg
rm $FLAMEGRAPH_FILE

# Clean up files
rm -rf uftrace.data*
rm -f gmon.out
