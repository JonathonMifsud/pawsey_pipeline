#!/bin/bash

# start an interactive session
salloc -n 4 --mem=20G --time=2:00:00

# travel to a safe location
cd /some/dir/

module load singularity/3.11.4
singularity pull --name ccmetagen:v1.1.5.sif docker://biocontainers/ccmetagen:v1.1.5_cv1
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
singularity pull --name trimmomatic:0.38.sif docker://biocontainers/trimmomatic:v0.38dfsg-1-deb_cv1
singularity pull --name fastqc:0.12.1.sif docker://staphb/fastqc:0.12.1

# KINGFISHER INSTALL IS A LITTLE HARDER, USE THE ALREADY MADE IMAGE OR CONTACT ME!
# Kingfisher was a bit of a pain and after ticket with the author we have a custom verison
#singularity pull --name kingfisher:0.0.0.sif docker://wwood/kingfisher:0.0.0
#wget "https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/OSA/0bfo7/0/ibm-aspera-connect_4.2.6.393_linux_x86_64.tar.gz?_gl=1*4ub25d*_ga*MTA5OTk3MTU1NC4xNjk1NzYzOTc0*_ga_FYECCCS21D*MTY5NTc2Mzk3My4xLjEuMTY5NTc2NDMyNy4wLjAuMA.."
#tar zxvf 'ibm-aspera-connect_4.2.6.393_linux_x86_64.tar.gz?_gl=1*4ub25d*_ga*MTA5OTk3MTU1NC4xNjk1NzYzOTc0*_ga_FYECCCS21D*MTY5NTc2Mzk3My4xLjEuMTY5NTc2NDMyNy4wLjAuMA..'
#./ibm-aspera-connect-4.2.6.393-linux-g2.12-64.sh
#
#singularity build --sandbox kingfisher_pawsey/ kingfisher:0.0.0.sif
#singularity shell kingfisher_pawsey/
#./ibm-aspera-connect_4.2.6.393_linux_x86_64.sh
#echo PATH=$PATH:/home/$USER/.aspera/connect/bin/ >> ~/.profile
#source ~/.profile
#exit
#nano singularity
## add the following line  PATH=$PATH:/home/$USER/.aspera/connect/bin/

wget https://data.broadinstitute.org/Trinity/TRINITY_SINGULARITY/trinityrnaseq.v2.15.1.simg
