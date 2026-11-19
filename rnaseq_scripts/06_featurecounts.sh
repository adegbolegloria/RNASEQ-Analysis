#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GTF="$BASE/Homo_sapiens.GRCh38.116.gtf"
OUT="$BASE/gene_counts_all6.txt"
[[ -s "$GTF" ]] || { echo "ERROR: GTF not found: $GTF" >&2; exit 1; }

SAMPLES=(SRR41438672 SRR41438673 SRR41438680 SRR41438681 SRR41438682 SRR41438683)
BAMS=()
for sample in "${SAMPLES[@]}"; do
    bam="$BASE/${sample}_sorted.bam"
    [[ -s "$bam" ]] || { echo "ERROR: Sorted BAM missing: $bam" >&2; exit 1; }
    BAMS+=("$bam")
done

# Deliberately create a new six-sample matrix; do not overwrite the earlier
# two-sample gene_counts.txt generated during practice.
if [[ -s "$OUT" ]]; then
    echo "SKIP featureCounts: $OUT already exists"
else
    featureCounts -T 4 -p --countReadPairs -a "$GTF" -o "$OUT" "${BAMS[@]}"
fi
echo "Six-sample count matrix: $OUT"
