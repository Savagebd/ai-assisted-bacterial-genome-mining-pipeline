# AI-Assisted Genome Mining Pipeline Explanation

## Project Setup Method

This pipeline follows the same reusable project-folder method as the bacterial genome analysis pipeline.

Template files stay in:

```text
~/Bioinformatics/00_Pipeline_Templates/ai_genome_mining_pipeline/
```

Each analysis project lives in:

```text
~/Bioinformatics/09_Projects/
```

For each new project, the user creates a project folder, creates only the `01_Genome_FASTA` input folder, places the assembled genome FASTA inside that folder, copies the reusable template files into the project, edits `config.env`, activates Conda, and runs:

```bash
./run_pipeline.sh
```

The template folder stays clean and does not contain numbered workflow folders.

## Project-Local Input and Output

This pipeline does not use a central raw data folder.

`01_Genome_FASTA` is the only required manually created workflow folder because the FASTA file must be placed there before the pipeline validates the input.

The input FASTA is stored inside the analysis project:

```text
01_Genome_FASTA/
```

All downstream output folders are generated automatically by `run_pipeline.sh`:

```text
02_QUAST_QC/
03_Bakta_Annotation/
04_AntiSMASH_BGC/
05_GECCO_ML/
06_Combined_Results/
07_Final_Report/
08_Notes/
```

The script protects `01_Genome_FASTA` and does not delete or modify the original input FASTA. Generated output folders may be replaced during reruns.

The `config.env` file makes each project reusable by storing the project path, sample name, FASTA path, thread count, and Bakta database path.

## Active Workflow

The active workflow has eight steps:

1. Input FASTA validation
2. SAMPLE_ID safety validation
3. QUAST assembly/genome quality control
4. Bakta genome annotation
5. antiSMASH biosynthetic gene cluster detection
6. GECCO machine-learning BGC prediction
7. Combined antiSMASH and GECCO BGC summary table
8. Final genome mining interpretation report

## Step 1: Input FASTA Validation

The pipeline checks that the configured genome FASTA file:

- Exists as a file
- Is inside `PROJECT_DIR/01_Genome_FASTA`
- Uses `.fna`, `.fa`, or `.fasta`
- Does not use path traversal such as `../`

This protects the project-local input layout and prevents accidental use of files outside the project folder.

## Step 2: SAMPLE_ID Safety Validation

The pipeline validates `SAMPLE_ID` before using it in output paths and file names.

Allowed characters are:

```text
letters, numbers, underscores, hyphens
```

This prevents unsafe sample names with spaces, slashes, or path traversal patterns.

## Step 3: QUAST Assembly/Genome Quality Control

QUAST evaluates the quality of the assembled genome before genome mining. It reports assembly statistics such as total length, contig count, N50, L50, GC content, and related metrics.

Genome mining results should be interpreted together with assembly quality. A fragmented or incomplete assembly can split biosynthetic gene clusters across contigs or cause candidate regions to be missed.

Output folder:

```text
02_QUAST_QC/
```

## Step 4: Bakta Genome Annotation

Bakta annotates the bacterial genome and produces standardized gene feature files. These annotations help interpret candidate biosynthetic regions by showing nearby coding sequences, RNA features, and functional predictions.

Output folder:

```text
03_Bakta_Annotation/
```

The user must provide the local Bakta database path in `config.env`.

## Step 5: antiSMASH Biosynthetic Gene Cluster Detection

antiSMASH detects biosynthetic gene clusters using rule-based methods and curated knowledge of known BGC classes. It produces a detailed HTML report and region files that are useful for manual review.

Output folder:

```text
04_AntiSMASH_BGC/
```

antiSMASH is especially useful when the genome contains recognizable BGC classes or gene arrangements similar to known biosynthetic systems.

## Step 6: GECCO Machine-Learning BGC Prediction

GECCO predicts candidate biosynthetic gene clusters using machine-learning methods. It produces cluster, feature, and gene tables that can be reviewed alongside antiSMASH results.

Output folder:

```text
05_GECCO_ML/
```

GECCO can identify candidates using a different strategy from antiSMASH, which makes it useful as a complementary genome mining tool.

## Why antiSMASH and GECCO Are Complementary

antiSMASH and GECCO approach BGC detection differently.

antiSMASH is rule-based and knowledge-driven. It is strong for known biosynthetic classes and produces detailed region diagrams and annotations.

GECCO is machine-learning based. It can provide candidate regions based on learned sequence patterns and probabilities.

Using both tools gives the user two independent views of potential biosynthetic regions. Candidates supported by both tools, or candidates with strong evidence in one tool and good annotation context, are useful targets for manual review.

## Step 7: Combined BGC Summary Table

The pipeline creates a combined summary table from antiSMASH region files and GECCO cluster predictions.

Output files:

```text
06_Combined_Results/combined_bgc_summary.tsv
06_Combined_Results/combined_bgc_summary.txt
```

The TSV table is designed as a first-pass index of predicted regions. It does not replace manual review of the original antiSMASH and GECCO outputs.

## Step 8: Final Genome Mining Interpretation Report

The pipeline writes a final interpretation report that summarizes the major output locations, counts candidate records, and gives a practical manual review checklist.

Output file:

```text
07_Final_Report/genome_mining_interpretation_report.txt
```

The final summary is written separately:

```text
07_Final_Report/genome_mining_summary.txt
```

## Reusable Configuration

The user creates `config.env` from:

```bash
cp config.example.env ./config.env
```

Important settings:

```text
PROJECT_DIR
SAMPLE_ID
GENOME_FASTA
THREADS
BAKTA_DB
```

`PROJECT_DIR` is the analysis project folder.

`GENOME_FASTA` points to the project-local FASTA file inside `PROJECT_DIR/01_Genome_FASTA`.

## Conda Environment

The software environment is documented in `environment.yml`.

Create the environment when needed:

```bash
conda env create -f environment.yml
```

Activate it before running the pipeline:

```bash
conda activate CortexAI
```

The pipeline does not create or modify Conda environments automatically.

## Reproducibility

This pipeline supports reproducibility because:

- Template files stay in `00_Pipeline_Templates`.
- Each analysis project lives in `09_Projects`.
- Input FASTA files are stored inside each project.
- Downstream outputs are generated inside each project.
- Project-specific settings are stored in `config.env`.
- Required tools are listed in `environment.yml`.
- Final reports are written in `07_Final_Report`.

## Final Statement

This project provides a reusable genome mining workflow for assembled bacterial genomes. It is designed for consistent project setup, clean template reuse, clear output organization, and practical downstream interpretation of antiSMASH and GECCO candidate biosynthetic gene clusters.
