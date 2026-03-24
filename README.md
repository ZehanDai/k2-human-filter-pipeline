# Human Kraken2 Database Builder

## Description
A script to build a Kraken2 database containing only human reference sequences, by which human genetic reads in sequencing data were filtered.
The build_human_kraken2_db.sh script extract human reference accession from official Kraken2 standard library, setting up a customized database.

## Dependencies
- **Kraken2** (>= 2.1.0)
- **wget** (for downloading)
- **gunzip** (for decompression)
- **bash** (>= 4.0)

## Usage
1. Clone the repository and enter the directory:
   ```bash
   git clone https://github.com/yourusername/human_kraken2_db_builder.git
   cd human_kraken2_db_builder
   ```

2. Make the script executable:
   ```bash
   chmod +x build_human_kraken2_db.sh
   ```

3. Run the script:
   ```bash
   ./build_human_kraken2_db.sh
   ```

4. 
```
kraken2 --db my_human_db \
        --threads 8 \
        --output output.txt \
        --report report.txt \
        --paired ERR10162502_1.fastq.gz ERR10162502_2.fastq.gz \
        --unclassified-out non_human_reads_#.fastq
```

"Note*: For paired-end data, Kraken2 expects a # in the filename, which it replaces with _1 and _2 for the two mates.

This will generate two files:
* non_human_reads_1.fastq
* non_human_reads_2.fastq

5. Alternatively, download human reference files from official website
   ```bash 
   kraken2-build --download-library human --use-ftp --db human_k2official
   ```
