#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$BASE/scripts"

usage() {
cat <<'HELP'
Usage:
  ./scripts/run_pipeline.sh
      Raw FastQC -> HISAT2 -> SAMtools -> featureCounts
  ./scripts/run_pipeline.sh --trim
      Raw FastQC -> optional trimming -> trimmed FastQC ->
      HISAT2 (trimmed reads where present) -> SAMtools -> featureCounts

Existing non-empty outputs are skipped. Remove an output only if you
intentionally want to regenerate it.
HELP
}

case "${1:-}" in
    "") 
        bash "$S/01_quality_control.sh"
        bash "$S/04_alignment.sh"
        ;;
    --trim)
        bash "$S/01_quality_control.sh"
        bash "$S/02_trimming.sh"
        bash "$S/03_quality_control_trimmed.sh"
        bash "$S/04_alignment.sh"
        ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

bash "$S/05_samtools.sh"
bash "$S/06_featurecounts.sh"
echo "Pipeline finished."
