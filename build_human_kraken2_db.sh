#!/bin/bash
set -e

# Build a Kraken2 database containing only human reference sequences.
# Purpose: human read filtering in metagenomic analysis.
# version: the Standard database, 20260226
# last tested on 20260324

DB_NAME="my_human_db"          # database name (adjustable)
THREADS=6                      # number of threads for building
TAXID=9606                     # human taxonomy ID

# Parse command line options
usage() {
    echo "Usage: $0 [-d database_name] [-t threads] [-h]"
    echo "  -d    Database name (default: my_human_db)"
    echo "  -t    Number of threads (default: 8)"
    echo "  -h    Show this help message"
    exit 0
}

while getopts "d:t:h" opt; do
    case $opt in
        d) DB_NAME="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done



# 1. Download the metadata file containing download URLs for human references
if [ ! -f library_report.tsv ]; then
    echo "Downloading library_report.tsv ..."
    wget -c https://genome-idx.s3.amazonaws.com/kraken/standard_20260226/library_report.tsv
fi

# 2. Extract download URLs for human reference sequences from the metadata
urls=$(awk -F'\t' 'NR>1 && $1=="human" {print $3}' library_report.tsv | sort -u)
if [ -z "$urls" ]; then
    echo "Error: No download URLs found for human reference sequences" >&2
    exit 1
fi

echo "Found URLs:"
echo "$urls"

# 3. Download all reference genome files (.fna.gz)
for url in "$urls"; do
    fn=$(basename "$url")
    echo "Processing file: $fn"
    if [ ! -f "$fn" ]; then
        echo "  Downloading ..."
        wget -c "$url"
    else
        echo "  File already exists, skipping download"
    fi
done

# 4. Decompress all .fna.gz files (if not already decompressed)
echo "Decompressing files ..."
for gz in *.fna.gz; do
    if [ -f "$gz" ]; then
        fna="${gz%.gz}"
        if [ ! -f "$fna" ]; then
            echo "  Decompressing $gz -> $fna"
            gunzip -k -d "$gz"
        else
            echo "  $fna already exists, skipping decompression"
        fi
    fi
done

# 5. Add kraken:taxid marker to FASTA headers of all .fna files
#    This allows Kraken2 to automatically recognize the taxonomy ID.
echo "Adding taxid marker to FASTA files ..."
for fna in *.fna; do
    if [ -f "$fna" ]; then
        echo "  Processing $fna"
        if ! head -n 1 "$fna" | grep -q "kraken:taxid"; then
            sed -i "s/^>/>kraken:taxid|$TAXID|/" "$fna"
        else
            echo "    Marker already present, skipping"
        fi
    fi
done

# 6. Download NCBI taxonomy information (required for database building)
echo "Downloading taxonomy ..."
kraken2-build --download-taxonomy --db "$DB_NAME" --use-ftp --skip-maps

# 7. Add all human reference sequences to the library
echo "Adding reference sequences to library ..."
for fna in *.fna; do
    if [ -f "$fna" ]; then
        echo "  Adding $fna"
        kraken2-build --add-to-library "$fna" --db "$DB_NAME" --threads "$THREADS"
    fi
done

# 8. Build Kraken2 index
echo "Building index ..."
kraken2-build --build --db "$DB_NAME" --threads "$THREADS"

echo "Database construction complete!"
echo "Database path: $DB_NAME"
