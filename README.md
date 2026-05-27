# AI-Assisted Bacterial Genome Mining Pipeline

Reusable genome mining workflow for assembled bacterial genomes using QUAST, Bakta, antiSMASH, GECCO, and candidate biosynthetic gene cluster reporting.


## What This Pipeline Does

The pipeline starts from an assembled bacterial genome FASTA file and runs a genome mining workflow:

```text
Assembled bacterial genome FASTA
-> QUAST assembly QC
-> Bakta genome annotation
-> antiSMASH BGC detection
-> GECCO machine-learning BGC prediction
-> combined BGC summary
-> final genome mining report
```

The pipeline prioritizes predicted candidate biosynthetic gene clusters. It does not prove compound production or biological activity.

## Input Requirements

This pipeline requires an assembled bacterial genome FASTA file, not raw FASTQ reads.

Place the input FASTA inside:

```text
01_Genome_FASTA/
```

Accepted extensions:

```text
.fna
.fa
.fasta
```

The `GENOME_FASTA` path in `config.env` must point to a file inside `PROJECT_DIR/01_Genome_FASTA`.

## Workflow Overview

1. Validate `config.env`, `SAMPLE_ID`, and FASTA input location.
2. Run QUAST for assembly/genome quality statistics.
3. Run Bakta for genome annotation.
4. Run antiSMASH for rule-based biosynthetic gene cluster detection.
5. Run GECCO for machine-learning-supported BGC prediction.
6. Combine antiSMASH and GECCO evidence into summary tables.
7. Generate a final genome mining interpretation report.

## Folder Structure

The project uses this numbered folder layout:

```text
01_Genome_FASTA
02_QUAST_QC
03_Bakta_Annotation
04_AntiSMASH_BGC
05_GECCO_ML
06_Combined_Results
07_Final_Report
08_Notes
```

Only `01_Genome_FASTA` needs to be created manually before running the pipeline. Downstream output folders are created automatically.

## Template Files

```text
run_pipeline.sh
config.example.env
environment.yml
README.md
PIPELINE_EXPLANATION.md
.gitignore
```

The reusable template folder should not contain numbered workflow outputs. Those folders belong inside each analysis project.

## Environment Setup

Create the Conda environment:

```bash
conda env create -f environment.yml
```

Activate it:

```bash
conda activate CortexAI
```

The pipeline does not create or modify Conda environments automatically.

## Configuration

Copy the public example configuration into a private local config file:

```bash
cp config.example.env config.env
nano config.env
```

Edit these values:

```text
PROJECT_DIR
SAMPLE_ID
GENOME_FASTA
THREADS
BAKTA_DB
```

Example:

```bash
PROJECT_DIR="$HOME/Bioinformatics/09_Projects/Your_Project_Name"
SAMPLE_ID="example_sample"
GENOME_FASTA="${PROJECT_DIR}/01_Genome_FASTA/example_genome.fna"
THREADS="4"
BAKTA_DB="$HOME/Bioinformatics/06_Tools/bakta_db/db-light"
```

`config.example.env` is safe to commit. `config.env` is local, sample-specific, and ignored by Git.

## How to Run

From the project folder:

```bash
chmod +x run_pipeline.sh
./run_pipeline.sh
```

## Output Explanation

QUAST assembly/genome quality report:

```text
02_QUAST_QC/report.html
02_QUAST_QC/report.txt
```

Bakta genome annotation:

```text
03_Bakta_Annotation/
```

antiSMASH biosynthetic gene cluster report:

```text
04_AntiSMASH_BGC/index.html
```

GECCO machine-learning BGC predictions:

```text
05_GECCO_ML/
```

Combined BGC summary:

```text
06_Combined_Results/combined_bgc_summary.tsv
06_Combined_Results/combined_bgc_summary.txt
```

Final genome mining reports:

```text
07_Final_Report/genome_mining_summary.txt
07_Final_Report/genome_mining_interpretation_report.txt
```

Logs:

```text
08_Notes/logs/
```

## Interpretation Notes

antiSMASH and GECCO provide complementary evidence:

- antiSMASH uses curated rules and known biosynthetic gene cluster models.
- GECCO uses machine-learning-supported prediction of candidate BGC regions.

Candidate regions supported by one or both tools are useful for manual review, literature comparison, and future prioritization. They are predictions, not experimental confirmation.

## Safety Design

The pipeline includes basic safety checks:

- `SAMPLE_ID` is validated before use in output names.
- `GENOME_FASTA` must resolve inside `PROJECT_DIR/01_Genome_FASTA`.
- Input FASTA files are not deleted during reruns.
- Rerun cleanup only removes generated output folders.
- Path traversal patterns are rejected for the input FASTA.

Always inspect `config.env` before running the workflow.

## Limitations

- This pipeline starts from assembled bacterial genome FASTA files.
- It does not process raw FASTQ reads.
- Predicted BGCs are candidate regions, not proof of metabolite production.
- antiSMASH and GECCO evidence supports prioritization, not experimental confirmation.
- The workflow does not prove biological activity, pathogenicity, or clinical relevance.
- DeepBGC is not part of the active workflow; it could be explored later as a separate future module or project.

## Future Improvements

Possible future additions include:

- richer BGC classification summaries
- BiG-SCAPE/CORASON-style comparative BGC analysis
- MIBiG similarity interpretation
- metabolite-family prioritization tables
- optional DeepBGC exploration as a separate module
- better HTML or Markdown final reporting
- comparative genome mining across multiple bacterial genomes

## Skills Demonstrated

This project demonstrates genome mining from assembled bacterial genomes, practical use of annotation and BGC prediction tools, safe project organization, reproducible configuration, and careful candidate-level interpretation. It fits between a foundational bacterial genome analysis pipeline and more advanced comparative or organism-specific genome mining workflows.

## Author

Created by Raihanul Islam (`Savagebd`) as part of a bioinformatics learning and portfolio development project.

This repository is shared publicly for transparency, portfolio development, and learning purposes. Direct copying and submitting this project as someone else's original coursework is not permitted.
