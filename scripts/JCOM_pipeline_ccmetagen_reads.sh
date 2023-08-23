#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"

while getopts "p:f:r:" 'OPTKEY'; do
    case "$OPTKEY" in
        'p')
            # Assign project name
            project="$OPTARG"
            ;;
        'f')
            # Assign file containing file names/accessions
            file_of_accessions="$OPTARG"
            ;;
        'r')
            # Assign root project name
            root_project="$OPTARG"
            ;;    
        '?')
            echo "INVALID OPTION -- ${OPTARG}" >&2
            exit 1
            ;;
        ':')
            echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
            exit 1
            ;;
    esac
done
shift $(( OPTIND - 1 ))

    if [ "$project" = "" ]
        then
            echo "No project string entered. Use e.g, -p JCOM_pipeline_virome"
    exit 1
    fi

    if [ "$root_project" = "" ]
        then
            echo "No root project string entered. Use e.g., -r VELAB or -r jcomvirome"
    exit 1
    fi
    

# Check if file containing file names/accessions is provided
if [ -z "$file_of_accessions" ]
    then
        echo "No file containing files to run specified. Running all files in /scratch/director2187/$user/$root_project/$project/contigs/final_contigs/"
        ls -d /scratch/director2187/$user/"$root_project"/"$project"/contigs/final_contigs/*.fa > /scratch/director2187/$user/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_ccmetagen
        export file_of_accessions="/scratch/director2187/$user/$root_project/$project/contigs/final_contigs/file_of_accessions_for_ccmetagen"
    else    
        export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
fi


# Determine the number of jobs needed from the length of input and format the J phrase for the pbs script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# If input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

sbatch --array $jPhrase \
    --output "/scratch/director2187/$user/$root_project/$project/logs/ccmetagen_$SLURM_ARRAY_TASK_ID_$project_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/director2187/$user/$root_project/$project/logs/ccmetagen_$SLURM_ARRAY_TASK_ID_$project_$(date '+%Y%m%d')_stderr.txt" \
    --export="project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project" \
    --time "$job_time" \
    --account="$root_project" \
    /scratch/director2187/$user/$root_project/$project/scripts/JCOM_pipeline_ccmetagen_reads.pbs
