#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLES=(SRR41438672 SRR41438673 SRR41438680 SRR41438681 SRR41438682 SRR41438683)

for sample in "${SAMPLES[@]}"; do
    sam="$BASE/${sample}.sam"
    bam="$BASE/${sample}_sorted.bam"
    bai="${bam}.bai"

    [[ -s "$sam" || -s "$bam" ]] || { echo "ERROR: Neither SAM nor sorted BAM found for $sample" >&2; exit 1; }

    if [[ -s "$bam" ]]; then
        echo "SKIP sorting $sample: sorted BAM already exists"
    else
        echo "Sorting $sample..."
        samtools sort -@ 4 -o "$bam" "$sam"
    fi

    if [[ -s "$bai" ]]; then
        echo "SKIP indexing $sample: BAM index already exists"
    else
        samtools index "$bam"
    fi

    samtools quickcheck -v "$bam"
    samtools flagstat "$bam" > "$BASE/${sample}_flagstat.txt"
done
echo "Sorted BAMs and indexes are in the main project directory."
