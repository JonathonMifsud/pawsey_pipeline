#!/bin/bash

# shell wrapper script to run blastx against the RdRp database
# provide a file containing the names of the read files to run only one per library! example only the first of the pairs
# if you do not provide it will use thoes in $project trimmed_reads

# Get the current working directory
wd=$(pwd)

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"

while getopts "i:d:p:r:" 'OPTKEY'; do
    case "$OPTKEY" in
            'i')
                # 
                input="$OPTARG"
                ;;
            'd')
                #
                db="$OPTARG"
                ;;
            'p')
                # 
                project="$OPTARG"
                ;; 
            'r')
                #
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

    if [ "$input" = "" ]
         then
            echo "No input string entered."
    exit 1
    fi

    if [ "$db" = "" ]
        then
            echo "No database specified. Use -d option to specify the database."
            exit 1
    fi

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

input_basename=$(basename "$input")

sbatch --output="/scratch/director2187/$user/$root_project/$project/logs/blastp_$input_basename_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/director2187/$user/$root_project/$project/logs/blastp_$input_basename_$(date '+%Y%m%d')_stderr.txt" \
    --export="input=$input,db=$db,wd=$wd" \
    --account="jcomvirome" \
     /scratch/director2187/$user/$root_project/$project/scripts/JCOM_pipeline_blastp_custom.slurm
    

