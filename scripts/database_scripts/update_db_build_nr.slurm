#!/bin/bash

# Holmes lab database update script
# Much of these scripts were orignally written for PBS by Justine Charon and further modified by Jon Mifsud 
# Ported to SLURM and usage of singularity by Jon Mifsud

#SBATCH --job-name="update_db_build_nr"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=980G
#SBATCH --mail-user=jmif9945@hpc.sydney.edu.au
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --partition=highmem
#SBATCH --output="/scratch/director2187/holmes_databases/logs/update_dd_build_nr_stout.txt"
#SBATCH --error="/scratch/director2187/holmes_databases/logs/update_db_build_nr_stderr.txt"
#SBATCH --time "96:00:00"
#SBATCH --account="director2187"


# set path to databases
path_db=/scratch/director2187/holmes_databases

module load singularity/3.11.4
singularity_image="/scratch/director2187/jmif9945/modules/diamond:version2.0.13.sif"

# Today is the database that will run today, it will be named with the following month
today=$(date -d "next month" +%b-%Y)

# past_file is the database that will be removed, it will be named with the previous month (two months before ""$today"")
past_file=$(date -d "last month" +%b-%Y)

# set edirect api key
export NCBI_API_KEY="e8e42ace5e30d6b9dd7d30393a53c35f1208"

cd "$path_db"/Blast/

# Convert to Blast or Diamond db format
function buildDiamondNR {
    singularity exec "$singularity_image" diamond makedb --in "$path_db"/Blast/nr."$today".gz \
        --db "$path_db"/Blast/nr."$today" \
        --taxonmap "$path_db"/Blast/prot.accession2taxid."$today" \
        --taxonnodes "$path_db"/Blast/taxdmp."$today"/nodes.dmp \
        --taxonnames "$path_db"/Blast/taxdmp."$today"/names.dmp \
        -t "$path_db"/
    singularity exec "$singularity_image" diamond dbinfo --db "$path_db"/Blast/nr."$today"   
    rm nr."$past_file".*
}

buildDiamondNR