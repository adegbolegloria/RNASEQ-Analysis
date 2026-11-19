#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX="$BASE/grch38/genome"
LOG_DIR="$BASE/hisat2_logs"
mkdir -p "$LOG_DIR"
SAMPLES=(SRR41438672 SRR41438673 SRR41438680 SRR41438681 SRR41438682 SRR41438683)

for sample in "${SAMPLES[@]}"; do
    # Existing SAM files in the project root are reused, including the two
    # samples already aligned manually (SRR41438673 and SRR41438681).
    if [[ -s "$BASE/${sample}.sam" ]]; then
        echo "SKIP alignment $sample: $sample.sam already exists in project directory"
        continue
    fi

    trim="$BASE/$sample/trimmed"
    if [[ -s "$trim/${sample}_R1_paired.fastq.gz" && -s "$trim/${sample}_R2_paired.fastq.gz" ]]; then
        r1="$trim/${sample}_R1_paired.fastq.gz"
        r2="$trim/${sample}_R2_paired.fastq.gz"
        echo "$sample: using trimmed paired reads"
    else
        r1="$BASE/$sample/${sample}_R1_subset.fastq.gz"
        r2="$BASE/$sample/${sample}_R2_subset.fastq.gz"
        echo "$sample: using raw subset reads"
    fi

    [[ -s "$r1" && -s "$r2" ]] || { echo "ERROR: Missing input reads for $sample" >&2; exit 1; }
    hisat2 -p 8 -x "$INDEX" -1 "$r1" -2 "$r2" \
        -S "$BASE/${sample}.sam" \
        2> "$LOG_DIR/${sample}_hisat2.log"
done
echo "SAM files are in the main project directory: $BASE"
