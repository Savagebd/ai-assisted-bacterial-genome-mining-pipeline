# AI-Assisted Bacterial Genome Mining Pipeline

This folder contains reusable template files for bacterial genome mining from an assembled bacterial genome FASTA file. It follows the same project setup method as the bacterial genome analysis pipeline: template files stay in `00_Pipeline_Templates`, and each analysis project lives in `09_Projects`.

## Active Workflow

1. Input FASTA validation
2. SAMPLE_ID safety validation
3. QUAST assembly/genome quality control
4. Bakta genome annotation
5. antiSMASH biosynthetic gene cluster detection
6. GECCO machine-learning BGC prediction
7. Combined antiSMASH and GECCO BGC summary table
8. Final genome mining interpretation report

## Template Files

```text
run_pipeline.sh
config.example.env
environment.yml
README.md
PIPELINE_EXPLANATION.md
.gitignore
```

The template folder should not contain numbered workflow folders. Those folders belong inside each analysis project.

## Step 1: Create a New Project Folder

```bash
mkdir -p ~/Bioinformatics/09_Projects/Your_Project_Name
cd ~/Bioinformatics/09_Projects/Your_Project_Name
```

## Step 2: Create Only the Input Folder

```bash
mkdir -p 01_Genome_FASTA
```

The user only creates `01_Genome_FASTA` manually because the FASTA must be placed there before validation. The pipeline automatically creates the remaining output folders during the run.

## Step 3: Place the FASTA File

Place the assembled bacterial genome FASTA file inside:

```text
01_Genome_FASTA/
```

Accepted extensions are `.fna`, `.fa`, and `.fasta`.

## Step 4: Copy Reusable Template Files

```bash
cp ~/Bioinformatics/00_Pipeline_Templates/ai_genome_mining_pipeline/run_pipeline.sh .
cp ~/Bioinformatics/00_Pipeline_Templates/ai_genome_mining_pipeline/config.example.env ./config.env
cp ~/Bioinformatics/00_Pipeline_Templates/ai_genome_mining_pipeline/environment.yml .
```

## Step 5: Edit config.env

```bash
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

`GENOME_FASTA` must point to the project-local FASTA file inside `01_Genome_FASTA/`.

`SAMPLE_ID` may only contain letters, numbers, underscores, and hyphens.

## Step 6: Activate Conda

```bash
conda activate CortexAI
```

## Step 7: Run the Pipeline

```bash
./run_pipeline.sh
```

## Output Folders Created Automatically

`run_pipeline.sh` automatically creates or replaces these generated output folders:

```text
02_QUAST_QC
03_Bakta_Annotation
04_AntiSMASH_BGC
05_GECCO_ML
06_Combined_Results
07_Final_Report
08_Notes
```

The script protects `01_Genome_FASTA` and does not delete or modify the original input FASTA.

## Final Project Folder Structure

```text
01_Genome_FASTA
02_QUAST_QC
03_Bakta_Annotation
04_AntiSMASH_BGC
05_GECCO_ML
06_Combined_Results
07_Final_Report
08_Notes
run_pipeline.sh
config.env
environment.yml
```

`run_pipeline.sh` uses the existing project-local FASTA directly. It does not copy input data from a central raw data folder.

## Important Outputs

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

Combined antiSMASH and GECCO summary:

```text
06_Combined_Results/combined_bgc_summary.tsv
06_Combined_Results/combined_bgc_summary.txt
```

Final reports:

```text
07_Final_Report/genome_mining_summary.txt
07_Final_Report/genome_mining_interpretation_report.txt
```

Pipeline log:

```text
08_Notes/logs/
```

## Environment Recreation

The required Conda environment can be recreated with:

```bash
conda env create -f environment.yml
conda activate CortexAI
```

`environment.yml` is only for recreating the environment. The pipeline does not create or modify Conda environments automatically.

## Safety Notes

The pipeline does not delete or modify files inside `01_Genome_FASTA`.

Generated output folders may be replaced during reruns.

Always check `config.env` carefully before running the pipeline.

## Author

Created by Raihanul Islam (Savagebd) as part of a bioinformatics learning and portfolio development project.

This repository is shared publicly for transparency, portfolio development, and learning purposes. Direct copying and submitting this project as someone else's original coursework is not permitted.
