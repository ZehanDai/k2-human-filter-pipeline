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


### 6. Output intepretation
Given the code described in 4, two files, output.txt and report.txt, would be generated. 

The `output.txt` contains detailed classification information for each read. Each line corresponds to one read, with fields separated by tabs. Example Lines: 
```t
U ERR10162502.1 0 150|151 0:116 |:| 0:117
C ERR10162502.9 9606 149|151 0:104 9606:1 0:10 |:| 0:117
```

#### Field Descriptions
| Column | Field Name | Description | Example Value |
|--------|------------|-------------|---------------|
| 1 | Classification status | `C` = classified<br>`U` = unclassified | `U`, `C` |
| 2 | Read ID | Sequence identifier, typically from the FASTQ file | `ERR10162502.1` |
| 3 | TaxID | Taxonomy ID. `0` indicates unclassified, otherwise an NCBI taxid | `0`, `9606` |
| 4 | Length | Single-end: `len`<br>Paired-end: `len1\|len2` | `150\|151` |
| 5 | k‑mer information | Mapping of k‑mer positions to taxids, separated by spaces. Paired‑end reads are separated by `\|:\|` | `0:116 \|:\| 0:117` |


The `report.txt` is a hierarchical summary of taxa assignment.
Example lines:
```
 99.93	7587151	7587151	U	0	unclassified
  0.07	5318	0	R	1	root
  0.07	5318	0	R1	131567	  cellular organisms
  0.07	5318	0	D	2759	    Eukaryota
  ...
  0.07	5318	0	F	9604	                                                        Hominidae
  0.07	5318	0	F1	207598	                                                          Homininae
  0.07	5318	0	G	9605	                                                            Homo
  0.07	5318	5318	S	9606	                                                              Homo sapiens
```

#### Field Descriptions
| Column | Field Name | Description | Example Value |
|--------|------------|-------------|---------------|
| 1 | Percentage | Percentage of total reads assigned to this taxon | `99.93` |
| 2 | Reads assigned to this taxon | Number of reads directly assigned to this node (excluding children) | `7587151` |
| 3 | Reads assigned to this taxon or its children | Total number of reads assigned to this node and all descendant nodes | `7587151` |
| 4 | Rank code | `U` = unclassified, `R` = root, `R1` = root's child, `D` = domain, `P` = phylum, `C` = class, `O` = order, `F` = family, `G` = genus, `S` = species | `U`, `R`, `D` |
| 5 | TaxID | NCBI taxonomy ID | `0`, `1`, `9606` |
| 6 | Scientific name | Scientific name of the taxon (indentation indicates hierarchy) | `unclassified`, `root`, `Homo sapiens` |

