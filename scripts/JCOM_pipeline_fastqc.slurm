#! /bin/bash
#PBS -P RDS-FSC-VELAB-RW
#SBATCH --job-name="fastqc"

#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=20G
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --mail-type=BEGIN,END,FAIL

module load fastqc
cd /scratch/director2187/$user/jcomvirome/"$project"/fastqc

readarray -t myarray < "$file_of_accessions"
export library_run=${myarray["$SLURM_ARRAY_TASK_ID"]}

fastqc "$library_run" \
    --format fastq \
    --threads 4 \
    --outdir /scratch/director2187/$user/jcomvirome/"$project"/fastqc

