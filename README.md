
HLA variant simulation script
=====

Script for simulating germline variants in HLA alleles using BamSurgeon.

This script can help to benchmark the accuracy of tools to detect germline variants in HLA genes.

This script has been used in NeoOncoHLA publication for the discovery of novel HLA alleles through the detection unknown HLA polymorphisms (by germline variant calling)

## Table of Contents
1. [Installation](#Installation)
2. [External-prerequisites](#External-prerequisites)
3. [Testing](#Testing)
4. [Usage](#Usage)
5. [Input-output](#Input-output)


## Installation:
Download and install

```
git clone git@github.com:OncoImmunity/hla_simulator.git
```
Edit `hla_simulator.sh` script and modify `BAMSURGEON_VENV` and `PICARDJAR` variables with your tool paths.

## External-prerequisites:
- [BamSurgeon](https://www.nature.com/articles/nmeth.3407):
```
git clone git@github.com:adamewing/bamsurgeon.git
python setup.py build
python setup.py install
```

- [Picard tools](https://github.com/broadinstitute/picard/):
```
wget https://github.com/broadinstitute/picard/releases/download/1.131/picard-tools-1.131.zip
unzip picard-tools-1.131.zip
```

- [Samtools](https://github.com/samtools/samtools):
```
git clone https://github.com/samtools/htslib.git
make -C htslib

git clone https://github.com/samtools/samtools.git
make -C samtools
```

- [Bedtools](https://github.com/arq5x/bedtools2/):
```
wget https://github.com/arq5x/bedtools2/releases/download/v2.29.1/bedtools-2.29.1.tar.gz
tar -zxvf bedtools-2.29.1.tar.gz
cd bedtools2
make
```

## Testing:
Run tests using:
```
cd test
bash run_tests.sh
```

If everything went OK, you will see the following message in the end:
```
Number of tests passed: 9/9
```

## Usage
Run `bash hla_simulator.sh -h` to display the help.
```
Simulate variants in HLA sequences using BamSurgeon

Syntax: simulation_experiment_runner [-r|g|a|b|v|n|l|M|m|e|c|o|h]
options:
r   Fasta file with reference HLA sequences
g   GTF with annotations of the alleles provided with -r
a   Mutate this reference HLA allele
b   Use this BAM file to spike variants in
v   Simulate this variant type: <deletion|insertion|snv> [Default: snv]
n   Number of variants to spike in [Default: 1]
l   INDEL maximum length [Default: 3]
M   Maximum VAF allowed [>0 and <=1.0] [Default: 1.0]
m   Minimum VAF allowed [>0 and <1.0] [Default: 0.99]
e   Simulate only in exonic regions
c   Simulate a SNV together with the indel variant specified with -v (insertion or deletion)
o   Output folder [Default: hla_simulation_experiment_output]
h   Print this help
```

## Input-output

**Input**
Required arguments include `-r` with a fasta file containing the allele to spike variants in, `-g` with the gene annotations of the given allele (exon coordinates), `-a` with the name of the allele to be mutated and `-b` with the bam file containing the reads mapped to the allele that has to be spiked with germline variant(s).

**Output**
 
- `spiked_R1.fq.gz` and `spiked_R2.fq.gz`: FASTQ files containing the spiked reads.
- `spiked.ground_truth.vcf`: VCF containing the spiked variant(s).
