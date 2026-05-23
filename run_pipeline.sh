#!/usr/bin/env bash

# Reusable AI-assisted bacterial genome mining pipeline.
# Usage:
#   cp config.example.env ./config.env
#   nano config.env
#   conda activate CortexAI
#   ./run_pipeline.sh

set -euo pipefail

CONFIG_FILE="${PWD}/config.env"

echo "================================================"
echo " AI-Assisted Bacterial Genome Mining Pipeline"
echo " Milestone 6: Genome Mining Interpretation"
echo "================================================"

if [[ ! -f "${CONFIG_FILE}" ]]; then
	echo "ERROR: Config file not found: ${CONFIG_FILE}" >&2
	echo "Copy config.example.env to config.env and edit it before running:" >&2
	echo "cp config.example.env config.env" >&2
	exit 1
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"

required_vars=(
	PROJECT_DIR
	SAMPLE_ID
	GENOME_FASTA
	THREADS
	BAKTA_DB
)

for var_name in "${required_vars[@]}"; do
	if [[ -z "${!var_name:-}" ]]; then
		echo "ERROR: Required config variable is missing or empty: ${var_name}" >&2
		exit 1
	fi
done

if [[ ! "${SAMPLE_ID}" =~ ^[A-Za-z0-9_-]+$ ]]; then
	echo "ERROR: SAMPLE_ID may only contain letters, numbers, underscores, and hyphens." >&2
	echo "ERROR: Do not use spaces, slashes, or path traversal such as ../ in SAMPLE_ID." >&2
	exit 1
fi

if [[ "${SAMPLE_ID}" == "." || "${SAMPLE_ID}" == ".." ]]; then
	echo "ERROR: SAMPLE_ID cannot be '.' or '..'." >&2
	exit 1
fi

PROJECT_DIR="$(realpath -m "${PROJECT_DIR}")"

INPUT_DIR="${PROJECT_DIR}/01_Genome_FASTA"
QUAST_DIR="${PROJECT_DIR}/02_QUAST_QC"
BAKTA_DIR="${PROJECT_DIR}/03_Bakta_Annotation"
ANTISMASH_DIR="${PROJECT_DIR}/04_AntiSMASH_BGC"
GECCO_DIR="${PROJECT_DIR}/05_GECCO_ML"
COMBINED_DIR="${PROJECT_DIR}/06_Combined_Results"
REPORT_DIR="${PROJECT_DIR}/07_Final_Report"
NOTES_DIR="${PROJECT_DIR}/08_Notes"
LOG_DIR="${NOTES_DIR}/logs"

if [[ ! -d "${PROJECT_DIR}" ]]; then
	echo "ERROR: PROJECT_DIR does not exist or is not a directory: ${PROJECT_DIR}" >&2
	echo "ERROR: Create the analysis project folder before running the pipeline." >&2
	exit 1
fi

if [[ ! -d "${INPUT_DIR}" ]]; then
	echo "ERROR: Input folder does not exist: ${INPUT_DIR}" >&2
	echo "ERROR: Create 01_Genome_FASTA inside PROJECT_DIR and place the FASTA file there." >&2
	exit 1
fi

case "${GENOME_FASTA}" in
	..|../*|*/..|*/../*)
		echo "ERROR: GENOME_FASTA must not use path traversal such as ../" >&2
		exit 1
		;;
esac

if [[ "${GENOME_FASTA}" = /* ]]; then
	GENOME_FASTA_PATH="${GENOME_FASTA}"
else
	GENOME_FASTA_PATH="${PROJECT_DIR}/${GENOME_FASTA}"
fi

if [[ ! -f "${GENOME_FASTA_PATH}" ]]; then
	echo "ERROR: Input genome FASTA file not found: ${GENOME_FASTA_PATH}" >&2
	echo "ERROR: Place the FASTA file in 01_Genome_FASTA and update GENOME_FASTA in config.env." >&2
	exit 1
fi

case "${GENOME_FASTA_PATH}" in
	*.fasta|*.fa|*.fna)
		;;
	*)
		echo "ERROR: GENOME_FASTA must end with .fasta, .fa, or .fna" >&2
		exit 1
		;;
esac

FASTA_ROOT="$(realpath -m "${INPUT_DIR}")"
REAL_FASTA="$(realpath -m "${GENOME_FASTA_PATH}")"

if [[ "${REAL_FASTA}" != "${FASTA_ROOT}/"* ]]; then
	echo "ERROR: GENOME_FASTA must point to a file inside ${FASTA_ROOT}." >&2
	echo "ERROR: Move the assembled genome FASTA into 01_Genome_FASTA and update config.env." >&2
	exit 1
fi

mkdir -p "${LOG_DIR}"

if [[ ! -d "${BAKTA_DB}" ]]; then
	echo "ERROR: BAKTA_DB does not exist or is not a directory: ${BAKTA_DB}" >&2
	exit 1
fi

dependencies=(
	quast.py
	bakta
	antismash
	gecco
)

for dependency in "${dependencies[@]}"; do
	if ! command -v "${dependency}" >/dev/null 2>&1; then
		echo "ERROR: Required command is not available on PATH: ${dependency}" >&2
		echo "ERROR: Activate the Conda environment before running the pipeline." >&2
		exit 1
	fi
done

GENOME_BASENAME="$(basename "${REAL_FASTA}")"
GENOME_BASENAME="${GENOME_BASENAME%.*}"

RUN_LOG="${LOG_DIR}/${SAMPLE_ID}_genome_mining_pipeline.log"
exec > >(tee -a "${RUN_LOG}") 2>&1

echo "Sample ID: ${SAMPLE_ID}"
echo "Project directory: ${PROJECT_DIR}"
echo "Config file: ${CONFIG_FILE}"
echo "Input genome FASTA: ${REAL_FASTA}"
echo "Threads: ${THREADS}"
echo "Pipeline log: ${RUN_LOG}"

reset_generated_dir() {
	local target_dir="$1"

	case "${target_dir}" in
		"${QUAST_DIR}"|\
		"${BAKTA_DIR}"|\
		"${ANTISMASH_DIR}"|\
		"${GECCO_DIR}"|\
		"${COMBINED_DIR}"|\
		"${REPORT_DIR}")
			if [[ ! -e "${target_dir}" ]]; then
				echo "Creating generated output folder: ${target_dir}"
				mkdir -p "${target_dir}"
			elif [[ ! -d "${target_dir}" ]]; then
				echo "ERROR: Expected generated output folder, but found a non-directory path: ${target_dir}" >&2
				exit 1
			elif [[ -z "$(find "${target_dir}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
				echo "Using empty generated output folder: ${target_dir}"
			else
				echo "Replacing previous generated output folder: ${target_dir}"
				rm -rf -- "${target_dir}"
				mkdir -p "${target_dir}"
			fi
			;;
		*)
			echo "ERROR: Refusing to reset non-allowlisted path: ${target_dir}" >&2
			exit 1
			;;
	esac
}

echo ""
echo "Step 1/8: Validating input FASTA"
echo "Input FASTA is present and uses a supported extension."

echo ""
echo "Step 2/8: Validating SAMPLE_ID safety"
echo "SAMPLE_ID is safe for output file and folder names."

echo ""
echo "Step 3/8: Running QUAST assembly quality control"
reset_generated_dir "${QUAST_DIR}"
quast.py "${REAL_FASTA}" \
	-o "${QUAST_DIR}" \
	-t "${THREADS}"

echo ""
echo "Step 4/8: Running Bakta genome annotation"
reset_generated_dir "${BAKTA_DIR}"
bakta "${REAL_FASTA}" \
	--db "${BAKTA_DB}" \
	--output "${BAKTA_DIR}" \
	--prefix "${SAMPLE_ID}" \
	--threads "${THREADS}" \
	--force

echo ""
echo "Step 5/8: Running antiSMASH biosynthetic gene cluster detection"
reset_generated_dir "${ANTISMASH_DIR}"
antismash "${REAL_FASTA}" \
	--output-dir "${ANTISMASH_DIR}" \
	--output-basename "${SAMPLE_ID}" \
	--cpus "${THREADS}" \
	--taxon bacteria \
	--genefinding-tool prodigal

echo ""
echo "Step 6/8: Running GECCO machine-learning BGC prediction"
reset_generated_dir "${GECCO_DIR}"
gecco run \
	-g "${REAL_FASTA}" \
	-o "${GECCO_DIR}" \
	-j "${THREADS}"

echo ""
echo "Step 7/8: Creating combined antiSMASH and GECCO BGC summary table"
reset_generated_dir "${COMBINED_DIR}"

COMBINED_TSV="${COMBINED_DIR}/combined_bgc_summary.tsv"
COMBINED_TXT="${COMBINED_DIR}/combined_bgc_summary.txt"
ANTISMASH_JSON="${ANTISMASH_DIR}/${SAMPLE_ID}.json"
GECCO_CLUSTERS="${GECCO_DIR}/${GENOME_BASENAME}.clusters.tsv"

printf "tool\tsource_id\tregion_or_cluster_id\tstart\tend\tpredicted_type\tconfidence_or_probability\toutput_file\tinterpretation_note\n" > "${COMBINED_TSV}"

while IFS= read -r REGION_GBK; do
	REGION_FILE="$(basename "${REGION_GBK}")"
	REGION_ID="${REGION_FILE%.gbk}"
	printf "antiSMASH\t%s\t%s\tNA\tNA\tCandidate BGC region\trule-based\t%s\tantiSMASH rule-based candidate biosynthetic region\n" \
		"${REGION_FILE}" \
		"${REGION_ID}" \
		"${REGION_GBK}" >> "${COMBINED_TSV}"
done < <(find "${ANTISMASH_DIR}" -maxdepth 1 -type f -name "*.region*.gbk" -print)

if [[ -f "${GECCO_CLUSTERS}" ]]; then
	awk -v output_file="${GECCO_CLUSTERS}" 'BEGIN { FS=OFS="\t" }
		NR == 1 {
			for (i = 1; i <= NF; i++) {
				col[$i] = i
			}
			next
		}
		NR > 1 {
			sequence_id = ("sequence_id" in col && $(col["sequence_id"]) != "") ? $(col["sequence_id"]) : "NA"
			cluster_id = ("cluster_id" in col && $(col["cluster_id"]) != "") ? $(col["cluster_id"]) : "NA"
			start = ("start" in col && $(col["start"]) != "") ? $(col["start"]) : "NA"
			end = ("end" in col && $(col["end"]) != "") ? $(col["end"]) : "NA"
			type = ("type" in col && $(col["type"]) != "") ? $(col["type"]) : "NA"
			if ("average_p" in col && $(col["average_p"]) != "") {
				confidence = $(col["average_p"])
			} else if ("max_p" in col && $(col["max_p"]) != "") {
				confidence = $(col["max_p"])
			} else {
				confidence = "NA"
			}
			print "GECCO", sequence_id, cluster_id, start, end, type, confidence, output_file, "GECCO machine-learning predicted BGC candidate"
		}
	' "${GECCO_CLUSTERS}" >> "${COMBINED_TSV}"
fi

cat > "${COMBINED_TXT}" <<COMBINED
AI-Assisted Bacterial Genome Mining Pipeline
Combined antiSMASH and GECCO BGC Summary

Sample ID: ${SAMPLE_ID}

antiSMASH summary output path: ${ANTISMASH_JSON}
GECCO summary output path: ${GECCO_CLUSTERS}
Combined TSV output path: ${COMBINED_TSV}

Short explanation:
- antiSMASH provides rule-based BGC prediction.
- GECCO provides machine-learning BGC prediction.
- The combined table is intended for easier comparison and downstream interpretation.
COMBINED

echo ""
echo "Step 8/8: Writing final genome mining interpretation report"
reset_generated_dir "${REPORT_DIR}"

INTERPRETATION_REPORT="${REPORT_DIR}/genome_mining_interpretation_report.txt"
SUMMARY_FILE="${REPORT_DIR}/genome_mining_summary.txt"

ANTISMASH_REGION_COUNT="$(find "${ANTISMASH_DIR}" -maxdepth 1 -type f -name "*.region*.gbk" -print | wc -l)"
GECCO_CLUSTER_COUNT="0"
if [[ -f "${GECCO_CLUSTERS}" ]]; then
	GECCO_CLUSTER_COUNT="$(awk 'NR > 1 { count++ } END { print count + 0 }' "${GECCO_CLUSTERS}")"
fi
COMBINED_RECORD_COUNT="$(awk 'NR > 1 { count++ } END { print count + 0 }' "${COMBINED_TSV}")"

cat > "${INTERPRETATION_REPORT}" <<REPORT
AI-Assisted Bacterial Genome Mining Interpretation Report
=========================================================

Sample ID: ${SAMPLE_ID}
Input genome FASTA: ${REAL_FASTA}

Overview
--------
This report summarizes the genome mining outputs generated from the assembled bacterial genome FASTA file.

Assembly Quality
----------------
QUAST results are available in:
${QUAST_DIR}

Review report.html and report.txt before interpreting genome mining results. Assembly fragmentation, contamination, or missing sequence can affect downstream BGC detection.

Genome Annotation
-----------------
Bakta annotation results are available in:
${BAKTA_DIR}

Bakta provides standardized bacterial gene annotations that help connect predicted biosynthetic regions to nearby genes and functional features.

Biosynthetic Gene Cluster Detection
-----------------------------------
antiSMASH output folder:
${ANTISMASH_DIR}

antiSMASH candidate region count from region GenBank files: ${ANTISMASH_REGION_COUNT}

antiSMASH is a rule-based genome mining tool. It is useful for detecting known classes of biosynthetic gene clusters and comparing them with characterized biosynthetic systems.

Machine-Learning BGC Prediction
-------------------------------
GECCO output folder:
${GECCO_DIR}

GECCO predicted cluster count from cluster table: ${GECCO_CLUSTER_COUNT}

GECCO uses machine-learning prediction and can provide complementary candidates that should be reviewed alongside antiSMASH results.

Combined Result
---------------
Combined BGC summary table:
${COMBINED_TSV}

Combined candidate record count: ${COMBINED_RECORD_COUNT}

Use the combined table as a first-pass index of candidate regions. The strongest candidates are usually those supported by clear tool output, biologically plausible genes, and good assembly context.

Recommended Manual Review
-------------------------
1. Open the QUAST report and confirm that the assembly is suitable for interpretation.
2. Review the antiSMASH HTML report for biosynthetic region classes and gene diagrams.
3. Review the GECCO cluster table for predicted cluster coordinates and probabilities.
4. Compare overlapping or nearby antiSMASH and GECCO predictions in the combined summary table.
5. Use Bakta annotation files to inspect genes near candidate BGCs.
REPORT

cat > "${SUMMARY_FILE}" <<SUMMARY
AI-Assisted Bacterial Genome Mining Pipeline
Milestone 6 Summary

Sample ID: ${SAMPLE_ID}
Project directory: ${PROJECT_DIR}
Input genome FASTA: ${REAL_FASTA}

Completed steps:
1. Input FASTA validation
2. SAMPLE_ID safety validation
3. QUAST assembly quality control
4. Bakta genome annotation
5. antiSMASH biosynthetic gene cluster detection
6. GECCO machine-learning BGC prediction
7. Combined antiSMASH and GECCO BGC summary table
8. Final genome mining interpretation report

Main output:
QUAST report folder: ${QUAST_DIR}
QUAST HTML report: ${QUAST_DIR}/report.html
QUAST text report: ${QUAST_DIR}/report.txt
Bakta output folder: ${BAKTA_DIR}
Bakta GFF3 annotation file: ${BAKTA_DIR}/${SAMPLE_ID}.gff3
Bakta TSV annotation file: ${BAKTA_DIR}/${SAMPLE_ID}.tsv
Bakta GenBank annotation file: ${BAKTA_DIR}/${SAMPLE_ID}.gbff
antiSMASH output folder: ${ANTISMASH_DIR}
antiSMASH HTML report: ${ANTISMASH_DIR}/index.html
antiSMASH GenBank output: ${ANTISMASH_DIR}/${SAMPLE_ID}.gbk
antiSMASH JSON output: ${ANTISMASH_JSON}
GECCO output folder: ${GECCO_DIR}
GECCO cluster table: ${GECCO_CLUSTERS}
GECCO features table: ${GECCO_DIR}/${GENOME_BASENAME}.features.tsv
GECCO genes table: ${GECCO_DIR}/${GENOME_BASENAME}.genes.tsv
Combined BGC summary folder: ${COMBINED_DIR}
Combined BGC summary TSV: ${COMBINED_TSV}
Combined BGC summary text report: ${COMBINED_TXT}
Final interpretation report: ${INTERPRETATION_REPORT}
Pipeline log: ${RUN_LOG}
SUMMARY

echo ""
echo "Pipeline completed successfully."
echo "Summary report: ${SUMMARY_FILE}"
echo "Interpretation report: ${INTERPRETATION_REPORT}"
