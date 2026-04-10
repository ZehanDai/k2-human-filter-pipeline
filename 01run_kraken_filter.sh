#!/bin/bash
set -e

# Test script for human filtering with Kraken2
# Downloads ERR10162502 paired-end reads and runs classification using a pre-built human database.
# Outputs non-human reads for downstream analysis.

# Default settings
DB_NAME="my_human_db"          # Path to the human database (must exist)
THREADS=8                      # Number of threads
OUTPUT_PREFIX="test_filter"    # Prefix for output files

# Check if database exists
if [ ! -d "$DB_NAME" ]; then
    echo "Error: Database '$DB_NAME' not found. Please build it first using build_human_kraken2_db.sh"
    exit 1
fi

# Check if Kraken2 is available
if ! command -v kraken2 &> /dev/null; then
    echo "Error: kraken2 not found in PATH"
    exit 1
fi

# Download test data if not already present
R1="ERR10162502_1.fastq.gz"
R2="ERR10162502_2.fastq.gz"
if [ ! -f "$R1" ]; then
    echo "Downloading $R1 ..."
    wget -c ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR101/002/ERR10162502/ERR10162502_1.fastq.gz
fi
if [ ! -f "$R2" ]; then
    echo "Downloading $R2 ..."
    wget -c ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR101/002/ERR10162502/ERR10162502_2.fastq.gz
fi

# Run Kraken2 classification
echo "Running Kraken2 classification..."
kraken2 --db "$DB_NAME" \
        --threads "$THREADS" \
        --output "${OUTPUT_PREFIX}_output.txt" \
        --report "${OUTPUT_PREFIX}_report.txt" \
        --paired "$R1" "$R2" \
        --unclassified-out "${OUTPUT_PREFIX}_non_human_#.fastq"

# Show summary statistics
echo -e "\n=== Classification Summary ==="
grep -E "^[UC]" "${OUTPUT_PREFIX}_output.txt" | cut -f1 | sort | uniq -c

echo -e "\n=== Report (top levels) ==="
head -n 10 "${OUTPUT_PREFIX}_report.txt"

echo -e "\n=== Output files ==="
ls -lh "${OUTPUT_PREFIX}"*

echo "Done. Non-human reads are in:"
echo "  ${OUTPUT_PREFIX}_non_human_1.fastq"
echo "  ${OUTPUT_PREFIX}_non_human_2.fastq"
