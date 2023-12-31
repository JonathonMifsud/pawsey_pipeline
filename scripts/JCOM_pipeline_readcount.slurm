#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

#SBATCH --job-name="unzip_and_get_read_count"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=20G
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --partition=work

# Change directory to the project's read_count directory. If the directory does not exist, exit the script.
cd /scratch/director2187/$user/"$root_project"/"$project"/read_count || { echo "Directory not found"; exit 1; }

# Read file_of_accessions line by line into an array
readarray -t myarray < "$file_of_accessions"

# Get the corresponding line from the array based on the SLURM_ARRAY_TASK_ID
export library_run=${myarray["$SLURM_ARRAY_TASK_ID"]}

# Remove .gz from the end of library_run
new_name=${library_run%".gz"}

# Extract the basename of new_name
library_id="$(basename -- $new_name)"

# Unzip the gzipped file and write the contents to new_name. If this fails, exit the script.
gunzip -c "$library_run" > "$new_name" || { echo "Failed to unzip $library_run"; exit 1; }

# Calculate the read count by dividing the total number of lines in the file by 4 (since each read in FASTQ format consists of 4 lines)
# The -n option with echo is used to prevent adding a new line
# The result is appended to a file named project_accessions_reads
echo -n "$library_id"","`echo $(cat $new_name|wc -l)/4 | bc`"\n" >> /scratch/director2187/$user/"$root_project"/"$project"/read_count/"$project"_accessions_reads

# Remove the unzipped file to save space. If this fails, print an error message but do not exit the script.
rm "$new_name" || echo "Failed to remove $new_name"

