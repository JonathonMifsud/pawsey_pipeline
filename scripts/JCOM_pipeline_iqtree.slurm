#! /bin/bash
#SBATCH --mail-user="$user@uni.sydney.edu.au"

#SBATCH --job-name="iqtree"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=6
#SBATCH --mem=40G
#SBATCH --partition=work

module load singularity/3.11.4

wd="$(dirname "${alignment}")"             # working dir 
filename="$(basename -- "$alignment")" # filename to be used in outfile
outpath="$wd"          # location of SRA files to be downloaded to
# cd working dir
cd "$wd" || exit

# Create a copy of the input alignment with the value of the -m flag prior to the date
file_basename="${filename%.*}"
file_extension="${filename##*.}"

# Remove any extra periods from the file_basename
file_basename_cleaned="${file_basename//.}"

new_filename="${file_basename_cleaned}_${model}.${file_extension}"
cp "$alignment" "$new_filename"

# Run iqtree with the new alignment filename
singularity exec "$singularity_image" iqtree -s "$new_filename" -st AA -m "$model" -bb 1000 --mem 90% -alrt 1000 -T AUTO

