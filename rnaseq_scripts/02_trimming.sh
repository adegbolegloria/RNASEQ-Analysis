#!/usr/bin/env bash
set -Eeuo pipefail
# Optional quality trimming only. Adapter clipping is not configured.
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLES=(SRR41438672 SRR41438673 SRR41438680 SRR41438681 SRR41438682 SRR41438683)

for sample in "${SAMPLES[@]}"; do
    sample_dir="$BASE/$sample"
    r1="$sample_dir/${sample}_R1_subset.fastq.gz"
    r2="$sample_dir/${sample}_R2_subset.fastq.gz"
    out="$sample_dir/trimmed"
    mkdir -p "$out"

    [[ -s "$r1" && -s "$r2" ]] || { echo "ERROR: Missing FASTQ pair for $sample" >&2; exit 1; }

    if [[ -s "$out/${sample}_R1_paired.fastq.gz" && -s "$out/${sample}_R2_paired.fastq.gz" ]]; then
        echo "SKIP trimming $sample: paired trimmed outputs already exist"
        continue
    fi

    trimmomatic PE -threads 4 -phred33 \
        "$r1" "$r2" \
        "$out/${sample}_R1_paired.fastq.gz" \
        "$out/${sample}_R1_unpaired.fastq.gz" \
        "$out/${sample}_R2_paired.fastq.gz" \
        "$out/${sample}_R2_unpaired.fastq.gz" \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done
echo "Trimmed files are stored inside each sample's trimmed/ directory."
