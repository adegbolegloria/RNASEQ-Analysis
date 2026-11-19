#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QC_DIR="$BASE/fastqc_trimmed"
mkdir -p "$QC_DIR"
SAMPLES=(SRR41438672 SRR41438673 SRR41438680 SRR41438681 SRR41438682 SRR41438683)

for sample in "${SAMPLES[@]}"; do
    trim="$BASE/$sample/trimmed"
    r1="$trim/${sample}_R1_paired.fastq.gz"
    r2="$trim/${sample}_R2_paired.fastq.gz"
    [[ -s "$r1" && -s "$r2" ]] || { echo "ERROR: Trimmed paired reads missing for $sample" >&2; exit 1; }

    if [[ -s "$QC_DIR/${sample}_R1_paired_fastqc.html" && -s "$QC_DIR/${sample}_R2_paired_fastqc.html" ]]; then
        echo "SKIP trimmed FastQC $sample: reports already exist"
        continue
    fi
    fastqc --threads 4 --outdir "$QC_DIR" "$r1" "$r2"
done
echo "Trimmed FastQC reports: $QC_DIR"
