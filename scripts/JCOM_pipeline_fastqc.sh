#!/bin/bash

# shell wrapper script to run fastqc for project folder

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"
account="director2187"
singularity_image="/scratch/$account/jmif9945/modules/blast:2.14.1.sif"

while getopts "p:f:r:s:" 'OPTKEY'; do
    case "$OPTKEY" in
            'p')
                # 
                project="$OPTARG"
                ;;
            'f')
                # 
                file_of_accessions="$OPTARG"
                ;;
            'r')
                #
                root_project="$OPTARG"
                ;;
            's')
                #
                singularity_image="$OPTARG"
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
    

    if [ "$file_of_accessions" = "" ]
        then
            echo "No file containing files to run specified running all files in /scratch/$account/$user/jcomvirome/$project/raw_reads/ and /scratch/$account/$user/jcomvirome/$project/trimmed_files/"
            ls -d /scratch/$account/$user/jcomvirome/"$project"/raw_reads/*.fastq.gz > /scratch/$account/$user/jcomvirome/"$project"/raw_reads/file_of_accessions
            ls -d /scratch/$account/$user/jcomvirome/"$project"/trimmed_reads/*.fastq.gz >> /scratch/$account/$user/jcomvirome/"$project"/raw_reads/file_of_accessions
            export file_of_accessions="/scratch/$account/$user/jcomvirome/$project/raw_reads/file_of_accessions"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

    if [ "$singularity_image" = "" ]
        then
            echo "No singularity image entered, please enter the full path to a singularity image for this script. This is typically hardcoded in the .sh script but can be manually overridden using the -s PATH"
    exit 1
    fi
    
#lets work out how many jobs we need from the length of input and format the J phrase for the.slurm script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

sbatch --export="project,file_of_accessions,singularity_image=$singularity_image" \
    --array $jPhrase \
    --output "/scratch/$account/$user/$root_project/$project/logs/fastqc_%A_%a_$project_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/$account/$user/$root_project/$project/logs/fastqc_%A_%a_$project_$(date '+%Y%m%d')_stderr.txt" \
    --time "1:00:00" \
    --account="$account" \
    /scratch/$account/$user/jcomvirome/random_scripts/project_scripts/project_fastqc.slurm
