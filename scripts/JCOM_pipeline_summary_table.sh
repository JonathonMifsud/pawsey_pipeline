#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
#                                 please ask before sharing these scripts :)                                  #
###############################################################################################################

# shell wrapper script to run the summary table script

# Set the default values
project="JCOM_pipeline_virome"
root_project="jcomvirome"
file_of_accessions=""

while getopts "p:r:f:" 'OPTKEY'; do
    case "$OPTKEY" in
        'p')
            project="$OPTARG"
            ;;
        '?')
            echo "INVALID OPTION -- ${OPTARG}" >&2
            exit 1
            ;;
        ':')
            echo "MISSING ARGUMENT for option -- ${OPTARG}" >&2
            exit 1
            ;;
        'r')
            root_project="$OPTARG"
            ;;
        'f')
            file_of_accessions="$OPTARG"
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

    if [ "$file_of_accessions" = "" ]
        then
            echo "No accessions provided (-f), Summary table will generated using all accessions in /scratch/"$root_project"/"$project"/contigs/ /scratch/"$root_project"/"$project"/blast_results/ etc"
        else    
            file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

sbatch --output="/group/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stout.txt" \
    --error="/group/$root_project/$project/logs/summary_table_creation_$project_$(date '+%Y%m%d')_stderr.txt" \
    --export="project=$project,root_project=$root_project,file_of_accessions=$file_of_accessions" \
    --time "$job_time" \
    --account="$root_project" \
    /group/"$root_project"/"$project"/scripts/JCOM_pipeline_summary_table.pbs