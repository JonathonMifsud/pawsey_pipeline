#!/bin/bash

###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# This script trims, assembles reads using trimmomatic and megahit, and then quantifies abundance using RSEM
# It runs with all .fastq.gz files in your raw_reads folder by default,
# or you can specify the accessions to look for using -f 

#SBATCH --job-name="TrimMegaAbun"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --partition=work

module load singularity/3.11.4

# Define functions

# Function to quality trim and remove adapter sequences from reads
readTrimmomatic() {
    # In case the TruSeq3 adapters are not in path we will download them to the working directory
    # Check the file as sometimes it doesn't download properly and results in unknown trimmer error
    if [[ "$layout" == "single" ]]; then
        singularity exec -e "$trimmomatic_image" cp /usr/local/bin/trinity-plugins/Trimmomatic/adapters/TruSeq3-SE.fa ./
        echo -e "MEGAHIT_SCRIPT: READ TRIMMOMATIC SINGLE - READ QC"
        # Quality control for single-end reads
        singularity exec -e "$trimmomatic_image" java -jar /usr/local/bin/trinity-plugins/Trimmomatic/trimmomatic-0.36.jar SE \
            -threads "$CPU" \
            "$inpath"/"$library_id".fastq.gz \
            /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed.fastq.gz \
            ILLUMINACLIP:TruSeq3-SE.fa:2:30:10 SLIDINGWINDOW:4:5 LEADING:5 TRAILING:5 MINLEN:25
    fi
    if [[ "$layout" == "paired" ]]; then
        # WILL NEED TO ADD IN THE PROPER ADAPTERS FOR NEXTERA AND CHECK IF YOU NEED TRUSEQ3-PE-2.fa
        singularity exec -e "$trimmomatic_image" cp /usr/local/bin/trinity-plugins/Trimmomatic/adapters/TruSeq3-PE.fa ./
        echo -e "MEGAHIT_SCRIPT: READ TRIMMOMATIC PAIRED - READ QC"
        singularity exec -e "$trimmomatic_image" java -jar /usr/local/bin/trinity-plugins/Trimmomatic/trimmomatic-0.36.jar PE \
            -threads "$CPU" \
            "$inpath"/"$library_id"_1.fastq.gz "$inpath"/"$library_id"_2.fastq.gz \
            /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed_R1.fastq.gz /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_removed_R1.fastq.gz /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed_R2.fastq.gz /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_removed_R2.fastq.gz \
            ILLUMINACLIP:joint_TruSeq3_Nextera-PE.fa:2:30:10 SLIDINGWINDOW:4:5 LEADING:5 TRAILING:5 MINLEN:25
    fi
   }
   
function callMegahit() {
    if [[ "$layout" == "single" ]]; then
        #echo -e "MEGAHIT_SCRIPT: MEGAHIT single - START"
        singularity exec -e "$megahit_image" megahit --num-cpu-threads "$CPU" \
        --memory 0.9 \
        -r /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed.fastq.gz \
        -o "$outpath"/"$library_id"_out
    fi

    if [[ "$layout" == "paired" ]]; then
        #echo -e "MEGAHIT_SCRIPT: MEGAHIT PAIRED - START"
        singularity exec -e "$megahit_image" megahit --num-cpu-threads "$CPU" \
        --memory 0.9 \
        -1 /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed_R1.fastq.gz \
        -2 /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed_R2.fastq.gz \
        -o "$outpath"/"$library_id"_out
    fi
    
# edit the contig name for later analyses and move all to current dir
    cat "$outpath"/"$library_id"_out/final.contigs.fa | sed "s/=//g" | sed "s/ /_/g" > "$outfinal"/"$library_id".contigs.fa
    cp "$outpath"/"$library_id"_out/log "$outlogs"/"$library_id".log
    rm -r "$outpath"/"$library_id"_out
}

function callRSEM() {

# FIX ME WITH NEW RSEM PATH
    if [[ "$layout" == "single" ]]; then
    singularity exec -e "$rsem_image" /usr/local/bin/util/align_and_estimate_abundance.pl --transcripts "$outfinal"/"$library_id".contigs.fa \
        --seqType fq \
        --single /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed.fastq.gz \
        --est_method RSEM \
        --aln_method bowtie2 \
        --output_dir /scratch/$account/$user/"$root_project"/"$project"/abundance/"$library_id"_abundance \
        --thread_count "$CPU" \
        --prep_reference
    fi

    if [[ "$layout" == "paired" ]]; then
    singularity exec -e "$rsem_image" /usr/local/bin/util/align_and_estimate_abundance.pl --transcripts "$outfinal"/"$library_id".contigs.fa \
        --seqType fq \
        --left /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed_R1.fastq.gz \
        --right /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/"$library_id"_trimmed_R2.fastq.gz \
        --est_method RSEM \
        --aln_method bowtie2 \
        --output_dir /scratch/$account/$user/"$root_project"/"$project"/abundance/"$library_id"_abundance \
        --thread_count "$CPU" \
        --prep_reference
    fi
    cp /scratch/$account/$user/"$root_project"/"$project"/abundance/"$library_id"_abundance/RSEM.isoforms.results "$outabundance"/"$library_id"_RSEM.isoforms.results
    rm /scratch/$account/$user/"$root_project"/"$project"/abundance/"$library_id"_abundance/bowtie2.bam
    rm "$outfinal"/"$library_id".contigs.fa.*
    #rm -r /project/"$root_project"/"$project"/abundance/"$library_id"_abundance
}

# variables change these to whatever you like!
wd=/scratch/$account/$user/"$root_project"/"$project"/contigs
inpath=/scratch/$account/$user/"$root_project"/"$project"/raw_reads         # location of reads and filenames
outpath=/scratch/$account/$user/"$root_project"/"$project"/contigs        # location of megahit output
outfinal=/scratch/$account/$user/"$root_project"/"$project"/contigs/final_contigs  # location of cleaned megahit output
outlogs=/scratch/$account/$user/"$root_project"/"$project"/contigs/final_logs  # location of cleaned megahit output
outabundance=/scratch/$account/$user/"$root_project"/"$project"/abundance/final_abundance  # location of cleaned megahit output
mkdir -p "$outfinal"                                     # create dir if this doesn't already exist
mkdir -p "$outlogs"   
mkdir -p "$outabundance" 
CPU=12                                                   # sets the CPU's for megahit
cd "$wd" || exit

# read in list of file names or accessions for example could be several fastq.gz files (paired or single) or just the accession id's
readarray -t myarray < "$file_of_accessions"
export library_run=${myarray["$SLURM_ARRAY_TASK_ID"]}
library_run_without_path="$(basename -- $library_run)"
library_id=$(echo $library_run_without_path | sed 's/\.fastq.gz//g' | sed 's/_*//g')

if [ -f "$inpath"/"$library_id"".fastq.gz" ] && [ ! -f "$inpath"/"$library_id""_1.fastq.gz" ]; then #e.g. if SRR1249328.fastq.gz exists and SRR1249328_1.fastq.gz doesn't layout == single
    export layout="single"
fi

if [ ! -f "$inpath"/"$library_id"".fastq.gz" ] && [ -f "$inpath"/"$library_id""_1.fastq.gz" ]; then #e.g. if SRR1249328.fastq.gz does not exist and SRR1249328_1.fastq.gz does layout == paired
    export layout="paired"
fi

if [ -f "$inpath"/"$library_id"".fastq.gz" ] && [ -f "$inpath"/"$library_id""_1.fastq.gz" ]; then #e.g. in the case both single and paired read files exist try to assemble using paired files, layout == paired
    export layout="paired"
fi

# Running the functions defined above
readTrimmomatic;
callMegahit;
callRSEM
