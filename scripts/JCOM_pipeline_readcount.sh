#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
###############################################################################################################

# shell wrapper script to run read count getter for project folder. Note this is run in trim_assembly_assemble script by default 
# if you are providing files include both the left and right file

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"
account="director2187"

while getopts "p:f:r:" 'OPTKEY'; do
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
            echo "No file containing files to run specified running all files in /scratch/$account/$user/$root_project/$project/trimmed_reads/"
            ls -d /scratch/$account/$user/"$root_project"/"$project"/trimmed_reads/*_trimmed*.fastq.gz > /scratch/$account/$user/"$root_project"/"$project"/raw_reads/file_of_accessions_for_readcount
            sed -i --posix '/.*trimmed_R2.fastq.gz/d' /scratch/$account/$user/"$root_project"/"$project"/raw_reads/file_of_accessions_for_readcount
            export file_of_accessions="/scratch/$account/$user/$root_project/$project/raw_reads/file_of_accessions_for_readcount"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
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
    --output "/scratch/$account/$user/$root_project/$project/logs/readcount_%A_%a_$project_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/$account/$user/$root_project/$project/logs/readcount_%A_%a_$project_$(date '+%Y%m%d')_stderr.txt" \
    --export="project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,singularity_image=$singularity_image,account=$account,user=$user" \
    --time "12:00:00" \
    --account="$account" \
    /scratch/$account/$user/"$root_project"/"$project"/scripts/JCOM_pipeline_readcount.slurm