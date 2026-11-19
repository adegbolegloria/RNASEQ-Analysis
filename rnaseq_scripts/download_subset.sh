
   #!/bin/bash

# RNA-seq data download, FASTQ conversion and read subsetting

set -euo pipefail

# Main project directory
BASE="$HOME/rnaseq_project"

# Number of read pairs to select from each sample
READ_PAIRS=500000

# Temporary directory for FASTQ conversion
TMP="$BASE/tmp"

# Six RNA-seq accessions
ACCESSIONS=(
    SRR41438672
    SRR41438680
    SRR41438682
    SRR41438683
)

# Create temporary directory
mkdir -p "$TMP"

# Move into project directory
cd "$BASE"

# Process each accession
for acc in "${ACCESSIONS[@]}"; do

    echo "======================================"
    echo "Processing $acc"
    echo "======================================"

    DIR="$BASE/$acc"

    # Full FASTQ files
    R1_GZ="$DIR/${acc}_1.fastq.gz"
    R2_GZ="$DIR/${acc}_2.fastq.gz"

    # Subset FASTQ files
    OUT_R1="$DIR/${acc}_R1_subset.fastq.gz"
    OUT_R2="$DIR/${acc}_R2_subset.fastq.gz"

    mkdir -p "$DIR"

    # Skip if both subset files already exist
    if [[ -s "$OUT_R1" && -s "$OUT_R2" ]]; then
        echo "$acc already has both subset files."
        echo "Skipping this sample."
        continue
    fi

    # Step 1: Download SRA data from NCBI
    if [[ ! -s "$DIR/$acc.sra" ]]; then

        echo "Downloading $acc from NCBI..."

        prefetch "$acc" --output-directory "$BASE"

    else
        echo "SRA file already downloaded."
    fi

    # Step 2: Convert SRA to paired-end FASTQ
    if [[ ! -s "$R1_GZ" || ! -s "$R2_GZ" ]]; then

        echo "Converting $acc to FASTQ..."

        fasterq-dump "$DIR/$acc.sra" \
            --split-files \
            --threads 4 \
            --progress \
            --outdir "$DIR" \
            --temp "$TMP"

        # Compress full FASTQ files
        [[ -s "$DIR/${acc}_1.fastq" ]] && gzip "$DIR/${acc}_1.fastq"
        [[ -s "$DIR/${acc}_2.fastq" ]] && gzip "$DIR/${acc}_2.fastq"

    else
        echo "Full FASTQ files already exist."
    fi

    # Confirm that both read files are available
    if [[ ! -s "$R1_GZ" || ! -s "$R2_GZ" ]]; then
        echo "ERROR: R1 or R2 is missing for $acc."
        exit 1
    fi

    # Step 3: Randomly sample R1
    echo "Selecting $READ_PAIRS read pairs..."

    SAMPLED_R1="$DIR/${acc}_R1_sampled_temp.fastq"
    IDS="$DIR/${acc}_selected_ids.txt"

    seqtk sample -s100 "$R1_GZ" "$READ_PAIRS" > "$SAMPLED_R1"

    # Step 4: Extract selected read identifiers
    awk 'NR % 4 == 1 {
        sub(/^@/, "")
        split($0, fields, /[[:space:]]/)
        print fields[1]
    }' "$SAMPLED_R1" > "$IDS"

    # Step 5: Extract matching reads from R1 and R2
    seqtk subseq "$R1_GZ" "$IDS" | gzip -c > "$OUT_R1"

    seqtk subseq "$R2_GZ" "$IDS" | gzip -c > "$OUT_R2"

    # Step 6: Check read counts
    COUNT_R1=$(gzip -cd "$OUT_R1" | awk 'END {print NR/4}')
    COUNT_R2=$(gzip -cd "$OUT_R2" | awk 'END {print NR/4}')

    if [[ "$COUNT_R1" != "$COUNT_R2" ]]; then
        echo "ERROR: R1 and R2 counts do not match for $acc."
        exit 1
    fi

    # Remove temporary sampling files
    rm -f "$SAMPLED_R1" "$IDS"

    echo "Completed $acc"
    echo "R1 reads: $COUNT_R1"
    echo "R2 reads: $COUNT_R2"

done

echo "======================================"
echo "All accessions processed."
echo "======================================"
