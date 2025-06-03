#!/bin/bash

FLAMEGRAPH_FILE="flamegraph_dump_publish.txt"

usage() {
    echo -e "Script to generate a flamegraph for the cvmfs_server publish command"
    echo -e "\nUsage: $0 [OPTIONS] repository_name"
	echo -e "\nOptions:"
	echo -e "  -o <output_file>   Specify the output file for uftrace replay (default: none)"
	echo -e "  -u <uftrace_options> Specify options for uftrace replay (for example: hide='std::*')"
	echo -e "  -h                  Show this help message"
    echo -e "\nMake sure CVMFS is built with the -pg compiler flag"
    echo -e "uftrace must be installed and available in the PATH"
    exit 1
}

UFTRACE_OPTIONS=""

# Check options
while getopts ":o:u:h" opt; do
	case "$opt" in
		o)
			GENERATE_TXT=1	
			OUTPUT_FILE="$OPTARG" ;;
		u)
			UFTRACE_OPTIONS="$OPTARG" ;;
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

echo "---Recording publish command---"
cvmfs_server transaction $REPO_NAME
# TODO: maybe add something in the transaction for more interesting publish results?
uftrace record --force -e /usr/bin/cvmfs_server publish $REPO_NAME

echo "---Generating uftrace replay output---"
if [ "${GENERATE_TXT:-0}" -eq 1 ]; then
	uftrace replay $UFTRACE_OPTIONS > $OUTPUT_FILE
fi

echo "---Generating flamegraph---"
if [ -f ./flamegraph.pl ]; then
	mkdir -p output
	uftrace dump --flame-graph $UFTRACE_OPTIONS > $FLAMEGRAPH_FILE
	./flamegraph.pl $FLAMEGRAPH_FILE > output/flamegraph_publish.svg
else
	echo "Warning: flamegraph.pl not found in the current directory. Skipping SVG generation."
fi

echo "---Cleaning up files---"
rm -rf uftrace.data*
rm -f $FLAMEGRAPH_FILE
rm -f gmon.out
