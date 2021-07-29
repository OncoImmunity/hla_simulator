#!/bin/sh

SECONDS=0
HLASIMULATOR="../hla_simulator.sh"
REF_FA="test_data/reference_hla_alleles.fasta"
REF_GTF="test_data/reference_hla_alleles.gtf"
INPUT_BAM="test_data/test.bam"
TARGET_HLA="HLA_A_02_03_01"

function Check_file_exists ()
{
	if [ ! -f ${1}"/spiked_R1.fq.gz" ]; then
        	echo "${1}/spiked_R1.fq.gz does not exist!"
        	exit 0
	fi
	rm -r ${1}
}

pass_tests=0
echo "Test_1"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM}
Check_file_exists "hla_simulation_experiment_output"
pass_tests=$((pass_tests+1))
echo "Test_2"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -o custom_output_dirname
Check_file_exists "custom_output_dirname"
pass_tests=$((pass_tests+1))
echo "Test_3"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -n 2
Check_file_exists "hla_simulation_experiment_output"
pass_tests=$((pass_tests+1))
echo "Test_4"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -v insertion -o insertion_simulation
Check_file_exists "insertion_simulation"
pass_tests=$((pass_tests+1))
echo "Test_5"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -v deletion -o deletion_simulation
Check_file_exists "deletion_simulation"
pass_tests=$((pass_tests+1))
echo "Test_6"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -v deletion -l 2 -o deletion_l2_simulation
Check_file_exists "deletion_l2_simulation"
pass_tests=$((pass_tests+1))
echo "Test_7"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -v deletion -l 2 -n 2 -o deletion_l2_n2_simulation
Check_file_exists "deletion_l2_n2_simulation"
pass_tests=$((pass_tests+1))
echo "Test_8"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -e -o only_exonic_simulation
Check_file_exists "only_exonic_simulation"
pass_tests=$((pass_tests+1))
echo "Test_9"
bash ${HLASIMULATOR} -r ${REF_FA} -g ${REF_GTF} -a ${TARGET_HLA} -b ${INPUT_BAM} -c -v insertion -o snv_and_insertion_out
Check_file_exists "snv_and_insertion_out"
pass_tests=$((pass_tests+1))


echo "####################################"
duration=$SECONDS
echo -e "Tests completed.\n$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
GREEN='\033[1;32m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORM=$(tput sgr0)
echo -e "Number of tests passed:${GREEN}${BOLD} $pass_tests/$pass_tests ${NC}${NORM}"
