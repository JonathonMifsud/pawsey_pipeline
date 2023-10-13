#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
###############################################################################################################

# This script will trim and assemble reads using trimmomatic and megahit and then quantify abundance using RSEM

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"
account="director2187"

trimmomatic_image="/scratch/$account/jmif9945/modules/trinityrnaseq.v2.15.1.simg"
megahit_image="/scratch/$account/jmif9945/modules/megahit:1.2.9.sif"
rsem_image="/scratch/$account/jmif9945/modules/trinityrnaseq.v2.15.1.simg"

# you can specify the accessions to look for using -f 
# or if you don't specify -f it will run will all of the .fastq.gz files in your raw_reads folder
# provide a file containing SRA accessions - make sure it is full path to file -f 

while getopts "p:f:r:t:m:a:" 'OPTKEY'; do
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
            't')
                #
                trimmomatic_image="$OPTARG"
                ;;
            'm')
                #
                megahit_image="$OPTARG"
                ;;    
            'a')
                #
                rsem_image="$OPTARG"
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
            echo "No file containing files to run specified running all files in /scratch/$account/$user/$root_project/$project/raw_reads/"
            ls -d /scratch/$account/$user/"$root_project"/"$project"/raw_reads/*.fastq.gz > /scratch/$account/$user/"$root_project"/"$project"/raw_reads/file_of_accessions_for_assembly
            export file_of_accessions="/scratch/$account/$user/$root_project/$project/raw_reads/file_of_accessions_for_assembly"
        else
        # just include the sra or lib id in this file as path is already specficied    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi
     
    if [ "$trimmomatic_image" = "" ]
        then
            echo "No trimmomatic image entered, please enter the full path to a singularity image for this script. This is typically hardcoded in the .sh script but can be manually overridden using the -t PATH"
    exit 1
    fi

    if [ "$megahit_image" = "" ]
        then
            echo "No megahit image entered, please enter the full path to a singularity image for this script. This is typically hardcoded in the .sh script but can be manually overridden using the -m PATH"
    exit 1
    fi

    if [ "$rsem_image" = "" ]
        then
            echo "No rsem image entered, please enter the full path to a singularity image for this script. This is typically hardcoded in the .sh script but can be manually overridden using the -a PATH"
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

sbatch --array $jPhrase \
    --output "/scratch/$account/$user/$root_project/$project/logs/trim_assemble_abundance_%A_%a_$project_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/$account/$user/$root_project/$project/logs/trim_assemble_abundance_%A_%a_$project_$(date '+%Y%m%d')_stderr.txt" \
    --export="trimmomatic_image=$trimmomatic_image,megahit_image=$megahit_image,rsem_image=$rsem_image,project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,singularity_image=$singularity_image,account=$account,user=$user" \
    --time "24:00:00" \
    --account="$account" \
    /scratch/$account/$user/"$root_project"/"$project"/scripts/JCOM_pipeline_trim_assembly_abundance.slurm
