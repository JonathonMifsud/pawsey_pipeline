#!/bin/bash 

#SBATCH --job-name="ccmetagen"
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --time=84:00:00


# Have to load in a newer verison of kma so that we can use tmp dir flag
CONDA_BASE=$(conda info --base) #figure out the path to conda directory so I can source it
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ccmetagen

# Module load
module load ccmetagen

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
kma -i "$inpath"/"$library_run" \
    -o "$outpath"/"$library_id"_out_kma \
    -t_db "$db" \
    -t "$threads" \
    -1t1 \
    -mem_mode \
    -tmp /scratch/director2187/$user/$root_project/ \
    -and

# Run CCMetagen
CCMetagen.py -i "$outpath"/"$library_id"_out_kma.res -o "$outpath"/"$library_id"_ccmetagen
