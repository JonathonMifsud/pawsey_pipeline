#! /bin/bash
#SBATCH --mail-user="$user@uni.sydney.edu.au"

#SBATCH --job-name="fasttree"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=20G
#SBATCH --partition=work

module load singularity/3.11.4

wd="$(dirname "${alignment}")"             # working dir 
filename="$(basename -- "$alignment")" # filename to be used in outfile
outpath="$wd"          # location of SRA files to be downloaded to
# cd working dir
cd "$wd" || exit

singularity exec "$singularity_image" FastTree -lg -quote "$alignment" > "$alignment"_fasttree.newick

