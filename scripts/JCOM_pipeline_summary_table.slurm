#!/bin/bash
# Script to take all of the blast ouput and construct a summary table

#SBATCH --job-name="summary_table"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --partition=work

## Blast output contigs should already be annotated with library ID

module load singularity/3.11.4

function condaSetUp(){
    CONDA_BASE=$(conda info --base) #figure out the path to conda directory so I can source it
    source $CONDA_BASE/etc/profile.d/conda.sh
    conda activate project_pipeline
}

function check_and_install_R_packages() {
    # Create a temporary directory
    conda activate r_env
    TMPDIR=$(mktemp -d)

    for PACKAGE_NAME in "$@"
    do
        echo "Checking package ${PACKAGE_NAME}"
        R -e 'if (!("'"${PACKAGE_NAME}"'" %in% installed.packages())) {print("Installing"); install.packages("'"${PACKAGE_NAME}"'", repos="https://cloud.r-project.org/", dependencies = TRUE, INSTALL_opts = "--no-lock")} else {print("Already installed")}'
    done

    # Remove the temporary directory
    rm -rf "$TMPDIR"
    conda deactivate
}

function createSummaryTable() {
    mkdir -p "$wd"/blast_results/summary_table_creation/ # Create the directory for storing summary table

    if [[ -z "$file_of_accessions" ]]; then
        abundance_files=("$abundance"/*_RSEM.isoforms.results)
        rdrp_blast_files=("$wd"/blast_results/*_rdrp_blastx_results.txt)
        rvdb_blast_files=("$wd"/blast_results/*_RVDB_blastx_results.txt)
        rdrp_blastcontigs_file=("$wd"/blast_results/*_rdrp_blastcontigs.fasta)
        rvdb_blastcontigs_file=("$wd"/blast_results/*_RVDB_blastcontigs.fasta)
    else
        accession_ids=$(cat "$file_of_accessions")
        abundance_files=()
        rdrp_blast_files=()
        rvdb_blast_files=()
        rdrp_blastcontigs_file=()
        rvdb_blastcontigs_file=()
        missing_files=()

        # Iterate over each accession ID and find corresponding files
        for id in $accession_ids; do
            abundance_file="$abundance/${id}_RSEM.isoforms.results"
            rdrp_blast_file="$wd/blast_results/${id}_rdrp_blastx_results.txt"
            rvdb_blast_file="$wd/blast_results/${id}_RVDB_blastx_results.txt"
            rdrp_blastcontigs="$wd/blast_results/${id}_rdrp_blastcontigs.fasta"
            rvdb_blastcontigs="$wd/blast_results/${id}_RVDB_blastcontigs.fasta"

            # Check if the abundance file exists
            if [ -f "$abundance_file" ]; then
                abundance_files+=("$abundance_file")
            else
                missing_files+=("Abundance file missing for accession ID: $id")
            fi

            # Check if the RdRp blast file exists
            if [ -f "$rdrp_blast_file" ]; then
                rdrp_blast_files+=("$rdrp_blast_file")
            else
                missing_files+=("RdRp blast file missing for accession ID: $id")
            fi

            # Check if the RVDB blast file exists
            if [ -f "$rvdb_blast_file" ]; then
                rvdb_blast_files+=("$rvdb_blast_file")
            else
                missing_files+=("RVDB blast file missing for accession ID: $id")
            fi

            # Check if the RdRp blastcontigs file exists
            if [ -f "$rdrp_blastcontigs" ]; then
                rdrp_blastcontigs_file+=("$rdrp_blastcontigs")
            else
                missing_files+=("RdRp blastcontigs file missing for accession ID: $id")
            fi

            # Check if the RVDB blastcontigs file exists
            if [ -f "$rvdb_blastcontigs" ]; then
                rvdb_blastcontigs_file+=("$rvdb_blastcontigs")
            else
                missing_files+=("RVDB blastcontigs file missing for accession ID: $id")
            fi
        done

        # Print missing files if any
        if [ ${#missing_files[@]} -gt 0 ]; then
            echo "${missing_files[@]}"
        fi
    fi

    # Take output of final abundance calculate standardized abundance and add library name to the contig name and join all together
    echo "Number of Abundance files loaded: ${#abundance_files[@]}" # Count the number of abundance files
    for i in "${abundance_files[@]}"; do
        id=$(basename "$i" | awk '{split($0,a,"_RSEM.isoforms.results"); print a[1]}') # Extract the ID from the file name
        awk -F'\t' -vOFS='\t' '{ $1 = $1 "_" id }1' id="$id" "$i" >"$abundance"/"$id"_anno_RSEM.isoforms.results # Add the library name to the contig name in the abundance file
    done

    # Join all the abundance files together and place in "$wd"/blast_results/summary_table_creation/
    cat "$abundance"/*_anno_RSEM.isoforms.results >"$wd"/blast_results/summary_table_creation/combined_abundance_table.txt # Concatenate all abundance files into one file
    rm "$abundance"/*_anno_RSEM.isoforms.results # Remove the individual abundance files

    # Do the same for the RdRp blast results for each library
    echo "Number of RdRp Blast files loaded: ${#rdrp_blast_files[@]}" # Count the number of RdRp blast files
    for i in "${rdrp_blast_files[@]}"; do
        id=$(basename "$i" | awk '{split($0,a,"_rdrp_blastx_results.txt"); print a[1]}') # Extract the ID from the file name
        awk -F'\t' -vOFS='\t' '{ $1 = $1 "_" id }1' id="$id" "$i" >"$wd"/blast_results/"$id"_anno_rdrp_blastx_results.txt # Add the library name to the contig name in the RdRp blast file
    done

    cat "$wd"/blast_results/*_anno_rdrp_blastx_results.txt >"$wd"/blast_results/summary_table_creation/combined_rdrp_blastx_results.txt # Concatenate all RdRp blast files into one file
    rm "$wd"/blast_results/*_anno_rdrp_blastx_results.txt # Remove the individual RdRp blast files

    # Do the same for the RVDB blast results for each library
    echo "Number of RVDB Blast files loaded: ${#rvdb_blast_files[@]}" # Count the number of RVDB blast files
    for i in "${rvdb_blast_files[@]}"; do
        id=$(basename "$i" | awk '{split($0,a,"_RVDB_blastx_results.txt"); print a[1]}') # Extract the ID from the file name
        awk -F'\t' -vOFS='\t' '{ $1 = $1 "_" id }1' id="$id" "$i" >"$wd"/blast_results/"$id"_anno_RVDB_blastx_results.txt # Add the library name to the contig name in the RVDB blast file
    done

    cat "$wd"/blast_results/*_anno_RVDB_blastx_results.txt >"$wd"/blast_results/summary_table_creation/combined_RVDB_blastx_results.txt # Concatenate all RVDB blast files into one file
    rm "$wd"/blast_results/*_anno_RVDB_blastx_results.txt # Remove the individual RVDB blast files

    # Create a combined virus contig file in "$wd"/blast_results/summary_table_creation/ so that we can more easily extract contigs at a later stage
    cat "${rdrp_blastcontigs_file[@]}" > "$wd"/blast_results/summary_table_creation/combined_rdrp_blastcontigs.fasta # Concatenate all RdRp blast contig files into one file
    cat "${rvdb_blastcontigs_file[@]}" >"$wd"/blast_results/summary_table_creation/combined_RVDB_blastcontigs.fasta # Concatenate all RVDB blast contig files into one file
    cat "$wd"/blast_results/summary_table_creation/combined_rdrp_blastcontigs.fasta >"$wd"/blast_results/summary_table_creation/combined_contigs.fasta # Create a combined contig file by copying the RdRp blast contig file
    cat "$wd"/blast_results/summary_table_creation/combined_RVDB_blastcontigs.fasta >>"$wd"/blast_results/summary_table_creation/combined_contigs.fasta # Append the RVDB blast contig file to the combined contig file
    rm "$wd"/blast_results/summary_table_creation/combined_rdrp_blastcontigs.fasta "$wd"/blast_results/summary_table_creation/combined_RVDB_blastcontigs.fasta # Remove the individual blast contig files

    conda deactivate
    conda activate r_env

    # Check if the files exist in the summary_table_creation folder, otherwise copy from the parent blast_results folder
    if [ ! -f "$wd"/blast_results/summary_table_creation/combined_nr_blastx_results.txt ] || [ ! -f "$wd"/blast_results/summary_table_creation/combined_nt_blastn_results.txt ]; then
        if [ -f "$wd"/blast_results/combined_nr_blastx_results.txt ] && [ -f "$wd"/blast_results/combined_nt_blastn_results.txt ]; then
            echo "Found combined_nr_blastx_results.txt aqstat nd combined_nt_blastn_results.txt in blast_results folder."
            # Copy the files to the summary_table_creation folder
            cp "$wd"/blast_results/combined_nr_blastx_results.txt "$wd"/blast_results/summary_table_creation/
            cp "$wd"/blast_results/combined_nt_blastn_results.txt "$wd"/blast_results/summary_table_creation/
            echo "Copied the files to summary_table_creation folder."
        else
            echo "Combined blast result files not found in summary_table_creation or blast_results folder."
            exit 1
        fi
    else
        echo "Found combined_nr_blastx_results.txt and combined_nt_blastn_results.txt in summary_table_creation folder."
    fi  

    if [[ -n "$file_of_accessions" && -f "$file_of_accessions" ]]; then
        # Function to filter the files based on accessions
        function filter_files() {
            local input_file="$1"  # Path to the input file
            local subset_file="$2"  # Path to the subset file

            local temp_dir=$(mktemp -d -p "$wd/blast_results/summary_table_creation/")  # Create a temporary directory in the desired directory

            echo "Input file: $input_file"
            echo "Subset file: $subset_file"
            echo "Temporary directory: $temp_dir"

            # Check if input_file exists and is readable
            if [[ ! -r "$input_file" ]]; then
                echo "Error: Input file '$input_file' does not exist or is not readable."
                rm -rf "$temp_dir"  # Clean up temporary directory
                return 1
            fi

            echo "Input file exists and is readable."

            # Check if subset_file exists and is readable
            if [[ ! -r "$subset_file" ]]; then
                echo "Error: Subset file '$subset_file' does not exist or is not readable."
                rm -rf "$temp_dir"  # Clean up temporary directory
                return 1
            fi

            echo "Subset file exists and is readable."

            local -A filtered_data  # Associative array to store filtered lines

            # Extract unique contigs
            echo "Extracting unique contigs..."
            cut -f1 "$input_file" | sort -u > "$temp_dir/contigs"

            # Process each accession and filter input
            echo "Processing each accession and filtering input..."
            while IFS= read -r accession; do
                echo "Accession: $accession"
                filtered_data["$accession"]=$(awk -v accession="$accession" '$0 ~ accession' "$input_file")
                echo "Filtered data for accession '$accession': ${filtered_data["$accession"]}"
            done < "$subset_file"

            # Write filtered data to separate files
            echo "Writing filtered data to separate files..."
            for accession in "${!filtered_data[@]}"; do
                echo "Accession: $accession"
                echo "${filtered_data["$accession"]}" > "$temp_dir/$accession.input"
                echo "Filtered data for accession '$accession' written to file: $temp_dir/$accession.input"
            done

            # Combine all input files
            echo "Combining all input files..."
            if ! cat "$temp_dir"/*.input > "$wd/blast_results/summary_table_creation/filtered_$(basename "$input_file")"; then
                echo "Error: Failed to combine input files."
                rm -rf "$temp_dir"  # Clean up temporary directory
                return 1
            fi

            echo "Input files combined successfully."

            # Clean up temporary directory
            echo "Cleaning up temporary directory: $temp_dir"
            rm -rf "$temp_dir"

            return 0  # Success
        }


        # Backup the original combined_nr_blastx_results.txt file
        if [[ -f "$wd/blast_results/summary_table_creation/combined_nr_blastx_results.txt" ]]; then
            cp "$wd/blast_results/summary_table_creation/combined_nr_blastx_results.txt" "$wd/blast_results/summary_table_creation/unfiltered_combined_nr_blastx_results.txt"
        fi

        # Filter the combined_nr_blastx_results.txt file
        if filter_files "$wd/blast_results/summary_table_creation/combined_nr_blastx_results.txt" "$file_of_accessions"; then
            echo "Filtering of combined_nr_blastx_results.txt completed successfully."
            # Copy the subset file to combined_nr_blastx_results.txt
            cp "$wd/blast_results/summary_table_creation/filtered_combined_nr_blastx_results.txt" "$wd/blast_results/summary_table_creation/combined_nr_blastx_results.txt"
        else
            echo "Error occurred while filtering combined_nr_blastx_results.txt."
        fi

        # Backup the original combined_nt_blastn_results.txt file
        if [[ -f "$wd/blast_results/summary_table_creation/combined_nt_blastn_results.txt" ]]; then
            cp "$wd/blast_results/summary_table_creation/combined_nt_blastn_results.txt" "$wd/blast_results/summary_table_creation/unfiltered_combined_nt_blastn_results.txt"
        fi

        # Filter the combined_nt_blastn_results.txt file
        if filter_files "$wd/blast_results/summary_table_creation/combined_nt_blastn_results.txt" "$file_of_accessions"; then
            echo "Filtering of combined_nt_blastn_results.txt completed successfully."
            # Copy the subset file to combined_nt_blastn_results.txt
            cp "$wd/blast_results/summary_table_creation/filtered_combined_nt_blastn_results.txt" "$wd/blast_results/summary_table_creation/combined_nt_blastn_results.txt"
        else
            echo "Error occurred while filtering combined_nt_blastn_results.txt."
        fi
    else
        echo "File of accessions not provided or does not exist. Skipping filtering."
    fi

    # Create the joint blast table
    echo "Creating joint blast table..."
    "$pathtoRscript"/Rscript "$scripts"/"$project"_create_blast_joint_table.R \
        --nr "$wd"/blast_results/summary_table_creation/combined_nr_blastx_results.txt \
        --nt "$wd"/blast_results/summary_table_creation/combined_nt_blastn_results.txt \
        --rdrp "$wd"/blast_results/summary_table_creation/combined_rdrp_blastx_results.txt \
        --rvdb "$wd"/blast_results/summary_table_creation/combined_RVDB_blastx_results.txt \
        --abundance "$wd"/blast_results/summary_table_creation/combined_abundance_table.txt \
        --readcounts "$wd"/read_count/"$project"_accessions_reads \
        --output "$wd"/blast_results/summary_table_creation/temp_joint_blast_table \
        --rdrp_tax "$taxonomy"/RdRp-scan_0.90.info \
        --rvdb_tax "$taxonomy"/RVDB_taxonomy_with_taxid.rds \
        --multi_lib

    if [ $? -eq 0 ]; then
        echo "Joint blast table created successfully."
    else
        echo "Error creating joint blast table."
        exit 1
    fi

    conda activate project_pipeline

    # Get lineage for all taxids
    echo "Getting lineage for taxids..."
    current_month=$(date +%b-%Y) # Get the current month
    taxonkit lineage -c "$wd"/blast_results/summary_table_creation/temp_joint_blast_table_taxids --data-dir /scratch/director2187/$user/VELAB/Databases/Blast/taxdmp."$current_month"/ \
        | awk '$2>0' \
        | cut -f 2- \
        | taxonkit reformat --output-ambiguous-result --data-dir /scratch/director2187/$user/VELAB/Databases/Blast/taxdmp."$current_month"/  -I 1 -r "Unassigned" -R "missing_taxid" --fill-miss-rank -f "{k}\t{p}\t{c}\t{o}\t{f}\t{g}\t{s}" \
        | csvtk add-header -t -n "taxid,lineage,kingdom,phylum,class,order,family,genus,species" >"$wd"/blast_results/summary_table_creation/temp_lineage_table

    if [ $? -eq 0 ]; then
        echo "Lineage table created successfully."
    else
        echo "Error creating lineage table."
        exit 1
    fi

    conda deactivate
    conda activate r_env

    # Filter blast table
    echo "Filtering blast table..."
    "$pathtoRscript"/Rscript "$scripts"/"$project"_filter_blast_table.R \
        --blast_table "$wd"/blast_results/summary_table_creation/temp_joint_blast_table \
        --taxnomy_table "$wd"/blast_results/summary_table_creation/temp_lineage_table \
        --output "$wd"/blast_results/summary_table_creation/"$project"_complete_blast_summary_table_$(date '+%Y%m%d')

    if [ $? -eq 0 ]; then
        echo "Complete blast summary table created successfully."
    else
        echo "Error creating complete blast summary table."
        exit 1
    fi
}

function extractContigsFromSummaryTable() {
    local summary_table
    summary_table=$(echo "$input_table" | rev | cut -f2 -d"_" | rev)
    # input a table from project_filter_blast_table.R
    # output a fasta file containing the contigs from that table
    cut -f1 -d"," "$input_table" | cut -f2 -d\" | uniq > "$wd"/temp_contig_list
    grep -A1 -I -Ff "$wd"/temp_contig_list "$wd"/blast_results/summary_table_creation/combined_contigs.fasta > "$wd"/blast_results/summary_table_creation/"$summary_table"_summary_table_blastcontigs_$(date '+%Y%m%d').fasta
    sed -i 's/--//' "$wd"/blast_results/summary_table_creation/"$summary_table"_summary_table_blastcontigs_$(date '+%Y%m%d').fasta # remove -- from the contigs
    sed -i '/^[[:space:]]*$/d' "$wd"/blast_results/summary_table_creation/"$summary_table"_summary_table_blastcontigs_$(date '+%Y%m%d').fasta # remove the white space
    rm "$wd"/temp_contig_list 
}

# the following are slightly broken and I haven't had a chance to fix so I currently don't split up the contig files by taxonomy 
function createTaxaFolderStructure(){
    summary_table=$(echo $input_table | rev | cut -f2 -d"_" | rev)
    cat "$wd"/blast_results/summary_table_creation/"$project"_complete_blast_summary_table_$(date '+%Y%m%d')_"$summary_table"_viruses_table_scaffold.csv | cut -f2 -d"," | sort | uniq | sed 's|\; .*||g' | sed 's|\;|\/|g' | sed 's/ //g' | sed -e "s|^|/project/$root_project/$project/blast_results/summary_table_creation/virus_fasta_files/|" > "$wd"/blast_results/summary_table_creation/dirs.txt 
    mkdir -p $(<"$wd"/blast_results/summary_table_creation/dirs.txt)
}

function createTaxaVirusContigFiles(){
    # requires createTaxaFolderStructure to be run
    summary_table=$(echo $input_table | rev | cut -f2 -d"_" | rev)
    for i in $(cat "$wd"/blast_results/summary_table_creation/"$project"_complete_blast_summary_table_$(date '+%Y%m%d')_"$summary_table"_viruses_table_scaffold.csv); do
        contig=$(echo $i | cut -f1 -d",")
        taxa=$(echo $i | cut -f2 -d"," | sed 's|\; .*||g' | sed 's/ //g' | rev | cut -f1 -d";" | rev)
        taxa_path=$(echo $i | cut -f2 -d"," | sed 's|\; .*||g' | sed 's|\;|\/|g' | sed 's/ //g' | sed -e "s|^|/project/$root_project/$project/blast_results/summary_table_creation/virus_fasta_files/|")
        grep -A1 "$contig" "$wd"/blast_results/summary_table_creation/"$summary_table"_summary_table_blastcontigs_$(date '+%Y%m%d').fasta >> "$taxa_path"/"$summary_table"_"$taxa"_contigs.fasta
        sed -i 's/--//' "$taxa_path"/"$summary_table"_"$taxa"_contigs.fasta # remove -- from the contigs
        sed -i '/^[[:space:]]*$/d' "$taxa_path"/"$summary_table"_"$taxa"_contigs.fasta # remove the white space
    done    
}


function cleanUp() {
    rm "$wd"/blast_results/summary_table_creation/"$project"_complete_blast_summary_table_$(date '+%Y%m%d')_*_viruses_table_scaffold.csv
    rm "$wd"/blast_results/summary_table_creation/temp_*
    #rm "$wd"/blast_results/summary_table_creation/dirs.txt
}

# Function to handle script failure
handleFailure() {
    echo "Script execution failed. Clean-up will not be performed."
    exit 1
}

# Function to check if the previous step was successful
checkStatus() {
    if [ $? -ne 0 ]; then
        handleFailure
    fi
}

# Exit the script if any command fails
set -e

wd="/project/$root_project/$project"
scripts="/project/$root_project/$project/scripts/"
abundance="/scratch/director2187/$user/$root_project/$project/abundance/final_abundance"
taxonomy="/project/VELAB/jcom_pipeline_taxonomy"
pathtoRscript="/project/$root_project/anaconda3/envs/r_env/lib/R/bin/"

condaSetUp && checkStatus
check_and_install_R_packages "vroom" "optparse" "dplyr" "purrr" "stringr" && checkStatus
createSummaryTable && checkStatus

input_table="$wd"/blast_results/summary_table_creation/"$project"_complete_blast_summary_table_$(date '+%Y%m%d')_likely_viruses.csv
extractContigsFromSummaryTable && checkStatus
#createTaxaFolderStructure && checkStatus
#createTaxaVirusContigFiles && checkStatus

input_table="$wd"/blast_results/summary_table_creation/"$project"_complete_blast_summary_table_$(date '+%Y%m%d')_potential_viruses.csv
extractContigsFromSummaryTable && checkStatus
#createTaxaFolderStructure && checkStatus
#createTaxaVirusContigFiles && checkStatus

#zip -r "$wd"/blast_results/summary_table_creation/virus_fasta_files.zip "$wd"/blast_results/summary_table_creation/virus_fasta_files

cleanUp && checkStatus
