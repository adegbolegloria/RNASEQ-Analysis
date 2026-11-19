#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QC_DIR="$BASE/fastqc_raw"
mkdir -p "$QC_DIR"
SAMPLES=(SRR41438672 SRR41438673 SRR41438680 SRR41438681 SRR41438682 SRR41438683)

for sample in "${SAMPLES[@]}"; do
    r1="$BASE/$sample/${sample}_R1_subset.fastq.gz"
    r2="$BASE/$sample/${sample}_R2_subset.fastq.gz"
    [[ -s "$r1" && -s "$r2" ]] || { echo "ERROR: Missing FASTQ pair for $sample" >&2; exit 1; }

    # Skip only when both reports already exist and are non-empty.
    if [[ -s "$QC_DIR/${sample}_R1_subset_fastqc.html" && -s "$QC_DIR/${sample}_R2_subset_fastqc.html" ]]; then
        echo "SKIP FastQC $sample: reports already exist"
        continue
    fi
    fastqc --threads 4 --outdir "$QC_DIR" "$r1" "$r2"
done
echo "Raw FastQC reports: $QC_DIR"
