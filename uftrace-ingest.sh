#!/bin/bash

FLAMEGRAPH_FILE="flamegraph_dump_ingest.txt"

usage() {
    echo -e "Script to generate a flamegraph for the cvmfs_server ingest command"
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
TAR_DIR="tarDir"
TAR_NAME="output.tar"

echo "---Preparing tar file---"
mkdir -p numbers
mkdir -p numbers/2/4/6/8
mkdir -p numbers/1/3/5/7/9
echo "these are even" > numbers/2/4/6/8/even
echo "these are odd" > numbers/1/3/5/7/9/odd
tar -cf $TAR_NAME numbers 

echo "---Recording ingest command---"
uftrace record --force /usr/bin/cvmfs_server ingest -t $TAR_NAME -b tarDir $REPO_NAME

echo "---Generating uftrace replay output---"
if [ "${GENERATE_TXT:-0}" -eq 1 ]; then
    uftrace replay $UFTRACE_OPTIONS > $OUTPUT_FILE
fi

echo "---Generating flamegraph---"
if [ -f ./flamegraph.pl ]; then
    mkdir -p output
	uftrace dump --flame-graph $UFTRACE_OPTIONS > $FLAMEGRAPH_FILE
    ./flamegraph.pl $FLAMEGRAPH_FILE > output/flamegraph_ingest.svg
else
    echo "Warning: flamegraph.pl not found in the current directory. Skipping SVG generation."
fi

echo "---Cleaning up repository---"
cvmfs_server transaction $REPO_NAME
rm -rf /cvmfs/$REPO_NAME/$TAR_DIR
cvmfs_server publish $REPO_NAME

echo "---Cleaning up files---"
rm -rf uftrace.data*
rm -f $FLAMEGRAPH_FILE
rm -f gmon.out
rm -f $TAR_NAME
rm -rf numbers
