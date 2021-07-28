# HLA variant simulation script

Script for simulating germline variants in HLA alleles using BamSurgeon.

This script can help to benchmark the accuracy of tools to detect germline variants in HLA genes.

This script has been used in NeoOncoHLA publication for the discovery of novel HLA alleles through the detection unknown HLA polymorphisms (by germline variant calling)

## Installation:

```
git clone git@github.com:OncoImmunity/hla_simulator.git
```

## External Prerequisites:
BamSurgeon:
```
git clone git@github.com:adamewing/bamsurgeon.git
python setup.py build
python setup.py install
```

Picard tools:
```
wget https://github.com/broadinstitute/picard/releases/download/1.131/picard-tools-1.131.zip
unzip picard-tools-1.131.zip
```

Samtools:

```
git clone https://github.com/samtools/htslib.git
make -C htslib

git clone https://github.com/samtools/samtools.git
make -C samtools
```

Bedtools:
```
wget https://github.com/arq5x/bedtools2/releases/download/v2.29.1/bedtools-2.29.1.tar.gz
tar -zxvf bedtools-2.29.1.tar.gz
cd bedtools2
make
```
