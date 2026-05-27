# AI-Assisted Genome Mining Pipeline Explanation

## Project Goal

This project provides a reusable genome mining workflow for assembled bacterial genomes. It combines assembly quality review, genome annotation, biosynthetic gene cluster prediction, candidate summary tables, and a final interpretation report.

The goal is not to prove that a bacterium produces a compound. The goal is to organize computational evidence so candidate biosynthetic gene clusters can be reviewed more systematically.

## Why Start From an Assembled Genome FASTA?

Genome mining tools such as antiSMASH and GECCO work on assembled genome sequences. Raw FASTQ reads must first be assembled in a separate genome analysis workflow.

This pipeline expects one assembled bacterial genome FASTA inside:

```text
01_Genome_FASTA/
```

The script validates that the FASTA is inside the project folder before running downstream tools.

## What Are Biosynthetic Gene Clusters?

Biosynthetic gene clusters, or BGCs, are groups of genes that may work together to produce specialized metabolites. In bacteria, these regions can be associated with compounds such as antibiotics, siderophores, toxins, pigments, or signaling molecules.

A predicted BGC is a candidate region. It is not proof that a compound is produced under laboratory or natural conditions.

## Tool Logic

### QUAST

QUAST evaluates the assembled genome before mining. Assembly quality matters because fragmented genomes can split BGCs across contigs or cause regions to be missed.

### Bakta

Bakta annotates genes and functional features in the bacterial genome. These annotations provide useful biological context around predicted BGC regions.

### antiSMASH

antiSMASH detects BGCs using curated rules and known biosynthetic gene cluster models. It is especially useful for recognizable BGC classes and produces detailed reports for manual inspection.

### GECCO

GECCO predicts BGCs using machine-learning-supported sequence patterns. It can provide evidence that complements antiSMASH because it uses a different prediction strategy.

GECCO results are still computational predictions. They should be treated as candidate evidence, not experimental proof.

## Why Use Both antiSMASH and GECCO?

antiSMASH and GECCO provide complementary views:

- antiSMASH is rule-based and knowledge-driven.
- GECCO is machine-learning-supported and pattern-based.

Candidate regions supported by both tools may deserve closer review. Regions supported by only one tool can still be useful, but they should be interpreted carefully.

## Combined BGC Summary

The pipeline creates combined summary files:

```text
06_Combined_Results/combined_bgc_summary.tsv
06_Combined_Results/combined_bgc_summary.txt
```

These files provide a first-pass index of predicted BGC evidence. They do not replace manual review of the full antiSMASH and GECCO outputs.

## Final Report

The final report summarizes:

- input genome information
- major output locations
- antiSMASH evidence
- GECCO evidence
- combined candidate BGC records
- practical interpretation notes

The report is meant to help a student or reviewer understand where to start when reviewing genome mining results.

## Why config.env Matters

The workflow is reusable because project-specific settings are stored in `config.env`:

```text
PROJECT_DIR
SAMPLE_ID
GENOME_FASTA
THREADS
BAKTA_DB
```

The public `config.example.env` shows the required variables. The private `config.env` contains local paths and is ignored by Git.

## Safety Design

The pipeline protects the input genome FASTA by requiring it to be inside `PROJECT_DIR/01_Genome_FASTA`. Generated output folders may be replaced during reruns, but the input folder is not deleted.

The script also validates the sample name before using it in file and folder names.

## What the Results Mean

The pipeline identifies predicted candidate BGC regions and organizes evidence from multiple tools.

It does not prove:

- compound production
- biological activity
- pathogenicity
- clinical relevance
- experimental discovery

Those conclusions require additional analysis, expert review, and experimental validation.

## Future Directions

Future versions could add comparative BGC analysis, MIBiG similarity summaries, metabolite-family prioritization, richer visualization, or a separate DeepBGC exploration module.

## Portfolio Value

This project demonstrates assembled-genome analysis, genome mining, machine-learning-supported candidate prediction, reproducible configuration, and careful interpretation of computational evidence.
