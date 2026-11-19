# Huh7 RNA-seq scripts: six-sample workflow

## Project layout expected

All commands are run from / or resolve paths relative to this project. The six FASTQ directories stay directly inside `~/rnaseq_project`:

```text
rnaseq_project/
├── scripts/
├── SRR41438672/
│   ├── SRR41438672_R1_subset.fastq.gz
│   └── SRR41438672_R2_subset.fastq.gz
├── SRR41438673/
│   ├── SRR41438673_R1_subset.fastq.gz
│   └── SRR41438673_R2_subset.fastq.gz
├── SRR41438680/
├── SRR41438681/
├── SRR41438682/
├── SRR41438683/
├── grch38/                 # HISAT2 index prefix: grch38/genome
└── Homo_sapiens.GRCh38.116.gtf
```

The scripts live in `scripts/`, but the FASTQ inputs remain in their six sample directories. Each script constructs the full path to each input, so you do not need to `cd` into each sample directory.

## Outputs

Alignment and count outputs are written to the main project directory to match the way the practice analysis was run:

- `SRR_ACCESSION.sam`
- `SRR_ACCESSION_sorted.bam`
- `SRR_ACCESSION_sorted.bam.bai`
- `SRR_ACCESSION_flagstat.txt`
- `gene_counts_all6.txt` and its `.summary`

FastQC reports are in `fastqc_raw/` and `fastqc_trimmed/`. HISAT2 logs are in `hisat2_logs/`. Optional trimmed FASTQs are placed in each sample's `trimmed/` subdirectory.

## Skip-existing behaviour

The scripts skip a stage for a sample if its expected non-empty output already exists:
- Raw/trimmed FastQC skips when both paired reports exist.
- Trimming skips when both paired trimmed outputs exist.
- HISAT2 skips when `SRR_ACCESSION.sam` already exists in the project root. This will reuse the existing `SRR41438673.sam` and `SRR41438681.sam`.
- SAMtools skips sorting if the sorted BAM exists, and skips indexing if its `.bai` exists.
- featureCounts writes a new `gene_counts_all6.txt`, preserving the existing two-sample `gene_counts.txt`.

Important: skip logic checks that a file exists and is non-empty; it does not prove that the file was generated from the latest settings. If you change parameters or inputs and want to rerun a stage, move or delete that stage's old output first. Do not delete the only copy of an important result.

## Setup and use

```bash
conda activate rnaseq
cd ~/rnaseq_project
chmod +x scripts/*.sh
```

Run raw QC first:

```bash
./scripts/01_quality_control.sh
```

Inspect the reports. Trimming is optional. If QC indicates trimming is appropriate:

```bash
./scripts/02_trimming.sh
./scripts/03_quality_control_trimmed.sh
```

The Trimmomatic script performs quality trimming only; adapter clipping is not included because no adapter FASTA file has been configured.

Run without trimming:

```bash
./scripts/run_pipeline.sh
```

Run with trimming:

```bash
./scripts/run_pipeline.sh --trim
```

When using `--trim`, the alignment script uses each sample's trimmed paired files if both exist. Otherwise, it uses the raw subset paired files.

## Notes

- Six run accessions are included: SRR41438672, SRR41438673, SRR41438680, SRR41438681, SRR41438682, SRR41438683.
- The script assumes each FASTQ pair is already present and correctly paired.
- HISAT2 index prefix is `grch38/genome`; edit `INDEX` in `04_alignment.sh` if your index basename differs.
- featureCounts uses paired-fragment counting (`-p --countReadPairs`).
- This pipeline ends at a six-sample gene count matrix. Differential expression analysis is a separate downstream stage.
