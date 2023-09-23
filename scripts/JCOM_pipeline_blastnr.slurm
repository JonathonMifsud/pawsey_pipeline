#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
###############################################################################################################

# Underlying.slurm script that is run using the wrapper script YOURPROJECT_blastnr.sh
# This script will run blastx on the contigs.fa file from the assembled contigs
# It will then extract the contigs that have a blast hit to the nr database

# I tend to run this once per project on a single file containing all the contigs concatenated together resulting from the Rdrp and RVDB blasts (i.e. the blastcontig.fa files in blast_results/)
#SBATCH --job-name="blastnr_array"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --partition=work

module load singularity/3.11.4

# blastx
function BlastxNR {
    singularity exec "$singularity_image" diamond blastx -q "$inpath"/"$library_id".contigs.fa -d "$db" -o "$outpath"/"$library_id"_nr_blastx_results.txt "$diamond_para" -f 6 qseqid qlen sseqid stitle staxids pident length evalue
}

#tool to extract contigs from assembly Blast to fasta
function blastToFasta {
    grep -i ".*" "$outpath"/"$library_id"_nr_blastx_results.txt | cut -f1 | uniq > "$outpath"/"$library_id""_temp_contig_names.txt" #by defult this will grab the contig name from every blast result line as I commonly use a custom protein database containing only viruses
	grep -A1 -I -Ff "$outpath"/"$library_id""_temp_contig_names.txt" "$inpath"/"$library_id".contigs.fa > "$outpath"/"$library_id"_nr_blastcontigs.fasta
    sed -i 's/--//' "$outpath"/"$library_id"_nr_blastcontigs.fasta # remove -- from the contigs
    sed -i '/^[[:space:]]*$/d' "$outpath"/"$library_id"_nr_blastcontigs.fasta # remove the white space
    sed --posix -i "/^\>/ s/$/"_$library_id"/" "$outpath"/"$library_id"_nr_blastcontigs.fasta # annotate the contigs
    rm "$outpath"/"$library_id""_temp_contig_names.txt"
}

# read in list of file names or accessions for example could be several fastq.gz files (paired or single) or just the accession id's
readarray -t myarray < "$file_of_accessions"
export library_run=${myarray["$SLURM_ARRAY_TASK_ID"]}
library_run_without_path="$(basename -- $library_run)"
library_id=$(echo $library_run_without_path | sed 's/\.contigs.fa//g')

# paths 
wd=/scratch/director2187/$user/"$root_project"/"$project"/blast_results
inpath=/scratch/director2187/$user/"$root_project"/"$project"/contigs/final_contigs   # location of reads and filenames
outpath=/scratch/director2187/$user/"$root_project"/"$project"/blast_results        # location of megahit output

# cd working dir
cd "$wd" || exit

BlastxNR
blastToFasta
