#!/bin/bash 

# PBS job options
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=130G
#SBATCH --job-name="ccmetagen"
#SBATCH --mail-user="$user@uni.sydney.edu.au"

#SBATCH --time=84:00:00
#SBATCH --partition=work

module load singularity/3.11.4

# Read in list of file names or accessions
readarray -t myarray < "$file_of_accessions"
export library_run=${myarray["$SLURM_ARRAY_TASK_ID"]}
library_run_without_path="$(basename -- $library_run)"
library_id=$(echo $library_run_without_path | sed 's/\.fastq.gz//g' | sed 's/_*//g')

# Variables to define working paths and parameters
wd=/scratch/director2187/$user/"$root_project"/"$project"/ccmetagen
inpath=/scratch/director2187/$user/"$root_project"/"$project"/raw_reads
outpath=/scratch/director2187/$user/"$root_project"/"$project"/ccmetagen
threads=4
db=/scratch/director2187/$user/VELAB/db_kma/ncbi_nt_no_env_11jun2019

# Check if directories exist and move to working directory
if [ -d "$wd" ]; then
    cd "$wd" || { echo "Error: Cannot change directory to $wd"; exit 1; }
else
    echo "Error: Directory $wd does not exist."
    exit 1
fi

# Map reads to database with kma
singularity exec "$singularity_image" kma -ipe "$inpath"/"$library_id"_1.fastq.gz "$inpath"/"$library_id"_2.fastq.gz \
    -o "$outpath"/"$library_id"_out_kma \
    -t_db "$db" \
    -t "$threads" \
    -1t1 \
    -mem_mode \
    -tmp /scratch/director2187/$user/$root_project/ \
    -and || { echo "Error: Failed to execute kma."; exit 1; }

# Run CCMetagen
singularity exec "$singularity_image" CCMetagen.py -i "$outpath"/"$library_id"_out_kma.res -o "$outpath"/"$library_id"_ccmetagen \
|| { echo "Error: Failed to execute CCMetagen."; exit 1; }

