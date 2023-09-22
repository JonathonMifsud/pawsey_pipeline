#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

# Create a backup directory
backup_dir="./pre_update"
mkdir -p "$backup_dir"

# Specify the file path
file_path="setup.sh"

# Update the variables using grep
root=$(grep -o 'root="[^"]*"' "$file_path" | cut -d'"' -f2)
project=$(grep -o 'project="[^"]*"' "$file_path" | cut -d'"' -f2)
email=$(grep -o 'email="[^"]*"' "$file_path" | cut -d'"' -f2)

# Move existing files (excluding the backup directory) to the backup directory
for file in *; do
  if [ "$file" != "$(basename "$backup_dir")" ]; then
    mv "$file" "$backup_dir/$file.bak"
  fi
done

# Clone the repository
git clone https://github.com/JonathonMifsud/pawsey_pipeline.git

# Navigate to the script directory
cd pawsey_pipeline/scripts

# Make all script files executable
chmod +x ./*

# Rename files with project name substitution
find . -type f -exec bash -c 'new_file="${1/JCOM_pipeline/$2}"; [ "$1" != "$new_file" ] && mv "$1" "$new_file"' _ {} "$project" \;

# Replace project-related variables in the script files
sed -i "s/JCOM_pipeline_virome/$project/g" *
sed -i "s/JCOM_pipeline/$project/g" *
sed -i "s/jcomvirome/$root/g" *
sed -i "s/jmif9945@uni.sydney.edu.au/$email/g" *

mv * ../../../
cd ../../../
rm -r BatchArtemisSRAMiner

# Copy missing files from the backup directory to the current directory
for file in "$backup_dir"/*; do
  base_file="${file##*/}"  # Extract the base filename from the file path

  if [[ ! -f "${base_file%.*}" && ! -f "${base_file%.*}.bak" ]]; then
    cp "$file" "${base_file%.*}"
    echo "Copied $file to ${base_file%.*}"
  fi
done

# Remove .bak extension from copied files
for file in *; do
  if [[ "$file" == *.bak ]]; then
    mv "$file" "${file%.bak}"
    echo "Removed .bak extension from $file"
  fi
done

# Script execution completed successfully
echo "Mining code has been updated."
