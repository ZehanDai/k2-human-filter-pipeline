#!/bin/bash
set -e

# ==================== Input Parameters ====================
R1="ERR10162502_1.fastq.gz"
R2="ERR10162502_2.fastq.gz"
ref="GCF_000001405.40_GRCh38.p14_genomic.fna"
THREADS=4

# ==================== Threshold Settings ====================
MIN_COVERAGE=0.8    # coverage ≥ 80%
MIN_IDENTITY=0.9    # identity ≥ 90%

# ==================== Reference Genome Indexing ====================
if [ ! -f "${ref}.bwt" ]; then
    echo "Indexing reference genome..."
    bwa index $ref
fi

# ==================== Alignment and Sorted BAM Generation ====================
if [ ! -f aligned.bam ]; then
    echo "Aligning paired-end reads with BWA-MEM..."
    # BWA can directly read gzip-compressed files
    bwa mem -t $THREADS $ref $R1 $R2 | \
        samtools view -b -h | \
        samtools sort -o aligned.bam -
    samtools index aligned.bam
fi

# ==================== Extract Alignment Metrics for Each Read ====================
if [ ! -f read_metrics.txt ]; then
    echo "Extracting alignment metrics..."
    samtools view aligned.bam | \
        awk 'BEGIN{OFS="\t"} {
            # Extract MD tag
            md=""
            for(i=12;i<=NF;i++){
                if($i ~ /^MD:Z:/){md=$i; break}
            }
            print $1, $2, $6, length($10), md
        }' > read_metrics.txt
fi

# ==================== Paired-End Read Filtering ====================
if [ ! -f passing_pairs.txt ]; then
    echo "Filtering read pairs by coverage ≥${MIN_COVERAGE} and identity ≥${MIN_IDENTITY}..."
    awk -v min_cov="$MIN_COVERAGE" -v min_id="$MIN_IDENTITY" '
    function parse_cigar(cigar,    arr, m, ins, del, len, op) {
        m=0; ins=0; del=0
        while(match(cigar, /[0-9]+[MIDNSHP=X]/)) {
            len = substr(cigar, RSTART, RLENGTH)
            op = substr(len, length(len))
            len = int(substr(len, 1, length(len)-1))
            if(op == "M" || op == "=" || op == "X") m += len
            else if(op == "I") ins += len
            else if(op == "D") del += len
            cigar = substr(cigar, RSTART+RLENGTH)
        }
        return m " " ins " " del
    }
    {
        read = $1
        flag = $2
        cigar = $3
        read_len = $4
        md = $5

        # Skip unmapped reads
        if(flag == 4) next

        # Count mismatches from MD tag
        mismatches = 0
        if(md != ""){
            gsub(/MD:Z:/, "", md)
            gsub(/\^[A-Za-z]+/, "", md)   # Remove deletion tags
            mismatches = gsub(/[A-Za-z]/, "&", md)  # Each letter corresponds to one mismatch
        }

        split(parse_cigar(cigar), arr, " ")
        m = arr[1]; ins = arr[2]; del = arr[3]

        aligned_bases = m + ins + del
        matches = m - mismatches

        if(read_len > 0){
            coverage = aligned_bases / read_len
            identity = (aligned_bases > 0) ? matches / aligned_bases : 0
            if(coverage >= min_cov && identity >= min_id){
                # Remove possible /1 or /2 suffix to obtain base read name
                base = read
                sub(/\/[12]$/, "", base)
                print base
            }
        }
    }' read_metrics.txt | sort | uniq -c | awk '$1==2 {print $2}' > passing_pairs.txt
fi

# ==================== Extract Passing Read Pairs to FASTQ ====================
echo "Extracting passing read pairs to FASTQ files..."
seqtk subseq $R1 passing_pairs.txt > filtered_R1.fastq
seqtk subseq $R2 passing_pairs.txt > filtered_R2.fastq

echo "Done. Output files: filtered_R1.fastq, filtered_R2.fastq"