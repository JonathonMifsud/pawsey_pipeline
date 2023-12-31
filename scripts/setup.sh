#!/bin/bash

# This script sets up a project with a specified structure in the provided root directory.
# It also moves all files from the current directory to the project's script directory 
# and replaces 'JCOM_pipeline' with the project name in file names and file contents.

# Root directory for all projects
root="jcomvirome"

# Project name
project="JCOM_pipeline_virome"

# email address
email="user@uni.sydney.edu.au"

# user
user="jmif9945"

# account
account="director2187"

# Define directory paths for convenience
group_dir="/scratch/$account/$user/${root}/${project}"
scratch_dir="/scratch/$account/$user/${root}/${project}"

# Create project directories in /project and /scratch
# The -p option creates parent directories as needed and doesn't throw an error if the directory already exists.
echo "Creating project directories..."
mkdir -p "${group_dir}"/{scripts,accession_lists,adapters,logs}
mkdir -p "${scratch_dir}"/{abundance,read_count,raw_reads,trimmed_reads,ccmetagen,blast_results,annotation,mapping,contigs/{final_logs,final_contigs},fastqc,read_count}
mkdir -p "${scratch_dir}"/abundance/final_abundance

# Move regular files (not directories) from the current directory to the project's scripts directory
echo "Moving files to the project's scripts directory..."
find ../adapters/ -maxdepth 1 -type f -exec cp {} "${group_dir}/adapters" \;
find . -maxdepth 1 -type f -exec cp {} "${group_dir}/scripts" \;

# Navigate to the project's scripts directory
cd "${group_dir}/scripts"

# Rename files with project name substitution
echo "Renaming files with project name substitution..."
for file in *; do
  new_file="${file/JCOM_pipeline/$project}"
  [ "$file" != "$new_file" ] && mv "$file" "$new_file"
done

# Replace project-related variables in the script files (excluding setup.sh)
echo "Replacing project-related variables in the script files..."
for file in *; do
  if [ "$file" != "setup.sh" ]; then
    sed -i "s/JCOM_pipeline_virome/$project/g" "$file"
    sed -i "s/JCOM_pipeline/$project/g" "$file"
    sed -i "s/_virome_virome/_virome/g" "$file"
    sed -i "s/jcomvirome/$root/g" "$file"
    sed -i "s/jmif9945@uni.sydney.edu.au/$email/g" "$file"
    sed -i "s/jmif9945/$user/g" "$file"
  fi
done

# Notify user about the project and scratch directory paths
echo "Project setup completed successfully."
echo "Project directory: ${group_dir}"
echo "Scratch directory: ${scratch_dir}"
