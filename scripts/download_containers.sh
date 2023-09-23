#!/bin/bash

# start an interactive session
salloc -n 4 --mem=20G --time=2:00:00

# travel to a safe location
cd /some/dir/

module load singularity/3.11.4
singularity pull --name ccmetagen:v1.1.5.sif docker://biocontainers/ccmetagen:v1.1.5_cv1
singularity pull --name kingfisher:0.3.0.sif docker://wwood/kingfisher:0.3.0
singularity pull --name sratoolkit:3.0.7.sif docker://pegi3s/sratoolkit:3.0.7
singularity pull --name fasttree_v2.1.10-2.sif docker://biocontainers/fasttree:v2.1.10-2-deb_cv1
singularity pull --name iqtree:v1.6.9dfsg-1.sif docker://biocontainers/iqtree:v1.6.9dfsg-1-deb_cv1
singularity pull --name mafft:v7.407-2.sif docker://biocontainers/mafft:v7.407-2-deb_cv1
singularity pull --name trimal:1.4.1.sif docker://reslp/trimal:1.4.1
singularity pull --name kma:1.4.10.sif docker://staphb/kma:1.4.10
singularity pull --name rsem:v1.3.1dfsg-1.sif docker://biocontainers/rsem:v1.3.1dfsg-1-deb_cv1
singularity pull --name jellyfish:v2.2.10-2.sif docker://biocontainers/jellyfish:v2.2.10-2-deb_cv1
singularity pull --name salmon:v0.12.0ds1-1b1.sif docker://biocontainers/salmon:v0.12.0ds1-1b1-deb_cv1
singularity pull --name blast:2.14.1.sif docker://ncbi/blast:2.14.1
singularity pull --name diamond:version2.0.13.sif docker://buchfink/diamond:version2.0.13
singularity pull --name megahit:1.2.9.sif docker://biocontainers/megahit:1.2.9_cv1
singularity pull --name trimmomatic:0.38.sif docker://staphb/trimmomatic:0.38
singularity pull --name fastqc:XXXX docker://biocontainers/fastqc:XXXX