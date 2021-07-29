#!/bin/sh

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.
SECONDS=0

# Initialize default values:
VARTYPE="snv"
MAX_INDEL_LENGTH=3
VAR_NUM=1
EXONIC=false # Only simulate variants on exonic regions
ADD_SNV=false
MINVAF="0.99"
MAXVAF="1.0"
OUTDIR="hla_simulation_experiment_output"

# Path to BAMSURGEON ENV
BAMSURGEON_VENV="/data/backup/tesla/p1_hla/experiment_ngs_395/mutate_hla/simulation/simulation_22042020/hlasimulator/somatic_simulations/bamsurgeon/venv/bin/activate"
#BAMSURGEON_VENV="./bamsurgeon/venv/bin/activate"
# Path to PIJARD jar file
#PICARDJAR="./picard-tools-1.131/picard.jar"
PICARDJAR="/data/backup/tesla/p1_hla/experiment_ngs_395/mutate_hla/bamsurgeon/picard-tools-1.131/picard.jar"

function Usage ()
{
	# Display Help
	echo "------------------------------------------------------------"
	echo "			HLA simulation experiment		  "
	echo "------------------------------------------------------------"
	echo "Simulate variants in HLA using BamSurgeon"
	echo
	echo "Syntax: simulation_experiment_runner [-r|g|a|b|v|n|l|M|m|e|c|o|h]"
	echo "options:"
	echo "r   Fasta file with reference HLA sequences"
	echo "g   GTF with annotations of the alleles provided with -r"
	echo "a   Mutate this reference HLA allele"
	echo "b   Use this BAM file to spike variants in"
	echo "v   Simulate this variant type: <deletion|insertion|snv> [Default: snv]"
	echo "n   Number of variants to spike in [Default: 1]"
	echo "l   INDEL maximum length [Default: 3]"
	echo "M   Maximum VAF allowed [>0 and <=1.0] [Default: 1.0]"
	echo "m   Minimum VAF allowed [>0 and <1.0] [Default: 0.99]"
	echo "e   Simulate only in exonic regions"
        echo "c   Simulate a SNV together with the indel variant specified with -v (insertion or deletion)"
	echo "o   Output folder [Default: hla_simulation_experiment_output]"
	echo "h   Print this help"
	echo
	exit 0
}

while getopts r:g:a:b:v:n:l:M:m:eco:h option
do
	case ${option} in
		h) Usage
		;;
		r) REF_FA=${OPTARG}
		;;
		g) REF_GTF=${OPTARG}
		;;
		a) HLA_TARGET=${OPTARG}
		;;
		b) INPUT_BAM=${OPTARG}
		;;
		v) VARTYPE=${OPTARG}
		;;
		n) VAR_NUM=${OPTARG}
		;;
		l) MAX_INDEL_LENGTH=${OPTARG}
		;;
		M) MAXVAF=${OPTARG}
		;;
		m) MINVAF=${OPTARG}
		;;
		e) EXONIC=true
		;;
		c) ADD_SNV=true
		;;
		o) OUTDIR=${OPTARG}
		;;
		:) printf "missing argument for -%s\n" "$OPTARG" >&2; Usage >&2; exit 1;;
		\?) printf "illegal option: -%s\n" "$OPTARG" >&2; Usage >&2; exit 1;;
	esac
done


# Mandatory arguments
if [ ! "${REF_FA}" ] || [ ! "${REF_GTF}" ] || [ ! "${INPUT_BAM}" ] || [ ! "${HLA_TARGET}" ]; then
	echo "arguments -r, -g, -a and -b must be provided"
 	Usage >&2
 	exit 1
fi

# [optional] Remove all options processed by getopts.
shift $(( OPTIND - 1 ))
[[ "${1}" == "--" ]] && shift

function Check_paths_exists ()
{
	if [ ! -f "${REF_FA}" ]; then
		echo "${REF_FA} does not exist!"
		exit 0
	fi
	if [ ! -f "${REF_GTF}" ]; then
		echo "${REF_GTF} does not exist!"
		exit 0
	fi
	if [ ! -f "${INPUT_BAM}" ]; then
		echo "${INPUT_BAM} does not exist!"
		exit 0
	fi
	if [ ! -f "${BAMSURGEON_VENV}" ]; then
		  echo "${BAMSURGEON_VENV} not found!"
		  exit 0
	 fi
	 if [ ! -f "${PICARDJAR}" ]; then
		  echo "${PICARDJAR} not found!"
		  exit 0
	 fi

}

function Check_variant_type ()
{
	if [ "${VARTYPE}" = "snv" ]; then
		variant_type_for_bs="snv"
	elif [ "${VARTYPE}" = "insertion" ] || [ "${VARTYPE}" = "deletion" ]; then
		variant_type_for_bs="indel"
	else
		echo "Please, specify the type of variant you want to spike with -v"
		Usage
	fi
}


function Check_vafs ()
{
	if (( ${MINVAF%%.*} >= ${MAXVAF%%.*} || ${MAXVAF%%.*} > 1 )); then
		echo -e "${MINVAF} should be smaller than ${MAXVAF}"
	fi
}


function Check_HLA_present_in_ref_files ()
{
	if ! grep -q ${HLA_TARGET} ${REF_FA}; then
  		echo -e "${HLA_TARGET} not present in ${REF_FA}!"
		exit
	fi
        if ! grep -q ${HLA_TARGET} ${REF_GTF}; then
                echo -e "${HLA_TARGET} not present in ${REF_GTF}!"
                exit
        fi
}


function Print_input_options ()
{
	echo "######### Experiment setup #########" | tee ${OUTDIR}/logger.log
	echo "Input BAM: ${INPUT_BAM}" | tee -a ${OUTDIR}/logger.log
	echo "Input HLAs: ${REF_FA}" | tee -a ${OUTDIR}/logger.log
	echo "HLA to be mutated: ${HLA_TARGET}" | tee -a ${OUTDIR}/logger.log
	echo "Variant type to simulate: ${VARTYPE}" | tee -a ${OUTDIR}/logger.log
	echo "Number of variants to simulate: ${VAR_NUM}" | tee -a ${OUTDIR}/logger.log
	echo "Maximum length of the variant: ${MAX_INDEL_LENGTH}" | tee -a ${OUTDIR}/logger.log
	echo "VAF range: [${MINVAF}, ${MAXVAF}]" | tee -a ${OUTDIR}/logger.log
	echo "Only spike exonic regions: ${EXONIC}" | tee -a ${OUTDIR}/logger.log
	echo "Output dir: ${OUTDIR}" | tee -a ${OUTDIR}/logger.log
}


# Input checks
Check_paths_exists
Check_variant_type
Check_vafs
Check_HLA_present_in_ref_files
mkdir -p ${OUTDIR}
Print_input_options


# ---------------------- Start -------------------- #
# ------------------------------------------------- #
source ${BAMSURGEON_VENV}

function Sort_bam ()
{
	samtools sort ${1} -o ${OUTDIR}/spiked_germline_snv_sorted.bam
}


function Index_bam ()
{
	if [ ! -f ${1}.bai ]; then
		samtools index ${1}
	fi
}


function Create_fasta_index ()
{
        if [ ! -f ${REF_FA}.fai ]; then
                samtools faidx ${REF_FA}
        fi
}


function Run_covered_segments ()
{
	covered_segments.py \
        -b ${INPUT_BAM} \
        -d 40 \
        -l 100 \
        | grep ${HLA_TARGET} \
        > ${OUTDIR}/${HLA_TARGET}"_covered_segments.bed"

}

function Extract_exonic_regions ()
{
        grep exon ${REF_GTF} | grep ${HLA_TARGET} | cut -f1,4,5 > ${OUTDIR}/${HLA_TARGET}"_exon.bed"
        bedtools intersect \
                -a ${OUTDIR}/${HLA_TARGET}"_exon.bed" \
                -b ${OUTDIR}/${HLA_TARGET}"_covered_segments.bed" \
                -wa \
                | awk '!x[$0]++' \
                > ${OUTDIR}/${HLA_TARGET}"_covered_segments_exonic.bed"
        cp ${OUTDIR}/${HLA_TARGET}"_covered_segments_exonic.bed" ${OUTDIR}/${HLA_TARGET}"_selected_regions.bed"
}


function Run_randomsites ()
{
	# $1 is the variant type
	randomsites.py \
        -b ${OUTDIR}/${HLA_TARGET}"_selected_regions.bed" \
        -g ${REF_FA} \
        -n 1000 \
        --avoidN \
        --minvaf ${MINVAF} \
        --maxvaf ${MAXVAF} \
        $1 \
        | shuf > ${OUTDIR}"/random_sites_out.tsv"
}

function Filter_by_length ()
{
	if [ "${1}" = "deletion" ]; then
        	awk -v maxlen="$MAX_INDEL_LENGTH" \
                'BEGIN {OFS = FS = "\t"} {dellen=$3-$2;if($5=="DEL" && dellen<=maxlen){print}}' \
                ${OUTDIR}"/random_sites_out.tsv" \
                > ${OUTDIR}/${HLA_TARGET}"_2BamSurgeon.bed"
                haplosize=""
	elif  [ "${1}" = "insertion" ]; then
        	awk -v maxlen="$MAX_INDEL_LENGTH" \
                'BEGIN {OFS = FS = "\t"} {inslen=length($6);if($5=="INS" && inslen<=maxlen){print}}' \
                ${OUTDIR}"/random_sites_out.tsv" \
                > ${OUTDIR}/${HLA_TARGET}"_2BamSurgeon.bed"
	else
        	cp ${OUTDIR}"/random_sites_out.tsv" ${OUTDIR}/${HLA_TARGET}"_2BamSurgeon.bed"
	fi
}


function Spike_snv ()
{
        addsnv.py \
        -v ${OUTDIR}/spiked_variant.tsv \
        -f ${INPUT_BAM} \
        -r ${REF_FA} \
        -o ${OUTDIR}/spiked_germline.bam \
        -p 10 \
        -m 1 \
        --picardjar ${PICARDJAR} \
        --minmutreads 5 \
        --tagreads \
        --aligner "mem" \
        -s 0.2 \
        -z 100 \
        &> /dev/null
}

function Spike_indel ()
{
        addindel.py \
        -v ${OUTDIR}/spiked_variant.tsv \
        -f ${INPUT_BAM} \
        -r ${REF_FA} \
        -o ${OUTDIR}/spiked_germline.bam \
        -p 10 \
        -m 1 \
        --picardjar ${PICARDJAR} \
        --minmutreads 5 \
        --tagreads \
        --aligner "mem" \
        -s 0.2 \
        &> /dev/null
}

function variant_spiking_loop ()
{
	# $1 = ${VAR_NUM}
	# $2 = ${variant_type_for_bs}
	# $3 = ${VARTYPE}
	counter=1
	successfully_spiked_variant_num=0
	while [[ "$successfully_spiked_variant_num" -lt "${1}" ]]; do
		echo -e "add${2}.py, iteration: ${counter}"

		# Shuffle and select a variant position
		shuf ${OUTDIR}/${HLA_TARGET}_2BamSurgeon.bed | head -n ${1} > ${OUTDIR}/spiked_variant.tsv

		# Call Bamsurgeon and spike the selected variants
		if [ "${3}" = "snv" ]; then
			Spike_snv
		else
			Spike_indel
		fi

		counter=$((counter+1))
		if [[ "${counter}" -gt 100 ]]; then
			echo -e "Too many iterations... something seems wrong!"
			exit 1
		fi

		simulated_vcf="spiked_germline.add"${2}".spiked_variant.vcf"
		if [ -f "${simulated_vcf}" ]; then
			# File exists
			successfully_spiked_variant_num=$(grep -vc '^#' ${simulated_vcf})
		fi

		rm -r "add"${2}*

	done
}


function Bam2fastq ()
{
	java -jar ${PICARDJAR} \
        SamToFastq \
        I=${OUTDIR}/spiked_germline.bam \
        F=${OUTDIR}/spiked_R1.fq \
        F2=${OUTDIR}/spiked_R2.fq \
        &> /dev/null

	gzip ${OUTDIR}/spiked*fq
}


# ---------- Define potential variant regions ---------- #
echo "######## Experiment started ########" | tee ${OUTDIR}/logger.log
Index_bam ${INPUT_BAM}
Create_fasta_index
Run_covered_segments

# ---------- Extract exonic regions (if required) ---------- #
if ${EXONIC}; then
	Extract_exonic_regions
else
	cp ${OUTDIR}/${HLA_TARGET}"_covered_segments.bed" ${OUTDIR}/${HLA_TARGET}"_selected_regions.bed"
fi


if ${ADD_SNV}; then
	Run_randomsites "snv"
	Filter_by_length "snv"
	variant_spiking_loop "1" "snv" "snv"
	mv ${OUTDIR}/spiked_germline.bam ${OUTDIR}/spiked_germline_snv.bam
	Sort_bam ${OUTDIR}/spiked_germline_snv.bam
	Index_bam ${OUTDIR}/spiked_germline_snv_sorted.bam
	rm ${OUTDIR}/spiked_germline_snv.bam
	INPUT_BAM=${OUTDIR}/spiked_germline_snv_sorted.bam
fi

# ---------- Generate potential mutations at random positions ---------- #
Run_randomsites ${variant_type_for_bs}

# ---------------------- Filter indels by length ----------------------- #
# Limit the length of indels to MAX_INDEL_LENGTH
# (defined by the user or 3 by default)
Filter_by_length ${VARTYPE}

# ----------------- Spike variants in the input BAM file---------------- #
variant_spiking_loop ${VAR_NUM} ${variant_type_for_bs} ${VARTYPE}


# ----------------------- Create ground truth VCF ---------------------- #
if ${ADD_SNV}; then
	cp spiked_germline.addsnv.spiked_variant.vcf ${OUTDIR}/spiked.ground_truth.vcf
	grep -v '#' ${simulated_vcf} >> ${OUTDIR}/spiked.ground_truth.vcf
	rm spiked_germline.add*.spiked_variant.vcf
else

	mv spiked_germline.add${variant_type_for_bs}.spiked_variant.vcf ${OUTDIR}/spiked.ground_truth.vcf
fi

# -------------------------- Spiked bam to fastq ---------------------- #
Bam2fastq


duration=$SECONDS
echo "####################################" | tee -a ${OUTDIR}/logger.log
echo -e "Job completed.\n$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed." | tee -a ${OUTDIR}/logger.log
