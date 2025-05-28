#!/bin/bash

FLAMEGRAPH_FILE="flamegraph_dump_publish.txt"

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
cvmfs_server transaction
uftrace record --force -e cvmfs_server publish

UFTRACE_OPTIONS="hide='std::*'"

# Generate txt output
if [ "${GENERATE_TXT:-0}" -eq 1 ]; then
	uftrace replay $UFTRACE_OPTIONS > $OUTPUT_FILE
fi

# Generate flamegraph
uftrace dump --flame-graph $UFTRACE_OPTIONS > $FLAMEGRAPH_FILE
./flamegraph.pl $FLAMEGRAPH_FILE > graph_publish.svg
rm $FLAMEGRAPH_FILE

# Clean up files
rm -rf uftrace.data*
rm gmon.out
