# Human Kraken2 Database Builder

## Description
A script to build a Kraken2 database containing only human reference sequences, used for filtering out human-derived reads from sequencing data.
The `build_human_kraken2_db.sh` script retrieves human reference sequences from the official Kraken2 standard library (specifically GRCh38 and T2T-CHM13v2.0) and creates a custom database.

## Dependencies
- **Kraken2** (>= 2.1.0)
- **wget** (for downloading)
- **gunzip** (for decompression)
- **bash** (>= 4.0)

## Usage
### 1. Clone the repository and enter the directory:
   ```bash
   git clone https://github.com/yourusername/human_kraken2_db_builder.git
   cd human_kraken2_db_builder
   ```

### 2. Make the script executable:
   ```bash
   chmod +x build_human_kraken2_db.sh
   ```

### 3. Run the script:
   ```bash
   ./build_human_kraken2_db.sh
   ```
  This would download and set up database.
  
### 4. Filter host read
Use Kraken2 to remove host-derived reads:
```
kraken2 --db my_human_db \
        --threads 8 \
        --output output.txt \
        --report report.txt \
        --paired ERR10162502_1.fastq.gz ERR10162502_2.fastq.gz \
        --unclassified-out non_human_reads_#.fastq
```
Note: For paired‑end data, Kraken2 requires a `#` placeholder in the output filename. This is automatically replaced with `_1` and `_2` for the two mates, producing:
* `non_human_reads_1.fastq`
* `non_human_reads_2.fastq`
  
A script `test_human_filter.sh` is provided to demonstrate how to download the two test SRA files. The files `ERR10162502_1.fastq.gz` and `ERR10162502_2.fastq.gz` are example reads from the SRA database (accession: ERX9699101), which originate from a project comparing different metagenomic taxonomic classification tools (Project ID: PRJEB55832).

### 5. Alternative: Using the official human reference library 
   ```bash 
   kraken2-build --download-library human --use-ftp --db YOUR_DIRECTORY_NAME # you may need to specify the database name
   ```
   This command creates a directory containing the human sequences (genomic and amino acid), ready to be used as the host database in step 4. 
