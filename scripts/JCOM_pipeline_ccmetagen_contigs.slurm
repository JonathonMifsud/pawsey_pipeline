#!/bin/bash 

#SBATCH --job-name="ccmetagen"
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --time=84:00:00
#SBATCH --partition=work

module load singularity/3.11.4

# read in list of file names or accessions for example could be several fastq.gz files (paired or single) or just the accession id's
readarray -t myarray < "$file_of_accessions"
export library_run=${myarray["$SLURM_ARRAY_TASK_ID"]}
library_run_without_path="$(basename -- $library_run)"
library_id=$(echo $library_run_without_path | sed 's/\.contigs.fa//g')


# variables change these to whatever you like!
wd=/scratch/director2187/$user/"$root_project"/"$project"/ccmetagen
inpath=/scratch/director2187/$user/"$root_project"/"$project"/contigs/final_contigs   # location of reads and filenames
outpath=/scratch/director2187/$user/"$root_project"/"$project"/ccmetagen        # location of megahit output     
threads=4
db=/scratch/director2187/$user/VELAB/db_kma/ncbi_nt_no_env_11jun2019
cd "$wd"

# Map reads to database with kma
singularity exec "$singularity_image" kma -i "$inpath"/"$library_run" \
    -o "$outpath"/"$library_id"_out_kma \
    -t_db "$db" \
    -t "$threads" \
    -1t1 \
    -mem_mode \
    -tmp /scratch/director2187/$user/$root_project/ \
    -and

# Run CCMetagen
singularity exec "$singularity_image" CCMetagen.py -i "$outpath"/"$library_id"_out_kma.res -o "$outpath"/"$library_id"_ccmetagen

