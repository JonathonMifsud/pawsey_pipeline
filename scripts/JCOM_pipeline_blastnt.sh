#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #   
#                                                JCO Mifsud                                                   # 
#                                                   2023                                                      # 
#                                                                                                             #
###############################################################################################################

# This script will run blastn on .contigs.fa files from the final_contigs folder
# It will then extract the contigs that have a blast hit to the nr database

# I tend to run this once per project on a single file containing all the contigs concatenated together resulting from the Rdrp and RVDB blasts (i.e. the blastcontig.fa files in blast_results/)

# provide a file containing SRA accessions - make sure it is full path to file -f 

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"
singularity_image="/scratch/director2187/jmif9945/modules/blast:2.14.1.sif"

while getopts "p:f:r:d:s:" 'OPTKEY'; do
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
            'd')
                #
                db="$OPTARG"
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

    if [ "$db" = "" ]
        then
            echo "No database specified. Use e.g., -d /scratch/director2187/$user/VELAB/Databases/Blast/nt.Jul-2023/nt"
    exit 1
    fi
    
    if [ "$file_of_accessions" = "" ]
        then
            echo "No file containing files to run specified running all files in /scratch/director2187/$user/$root_project/$project/contigs/final_contigs/"
            ls -d /scratch/director2187/$user/"$root_project"/"$project"/contigs/final_contigs/*.fa > /scratch/director2187/$user/"$root_project"/"$project"/contigs/final_contigs/file_of_accessions_for_blastNT
            export file_of_accessions="/scratch/director2187/$user/$root_project/$project/contigs/final_contigs/file_of_accessions_for_blastNT"
        else    
            export file_of_accessions=$(ls -d "$file_of_accessions") # Get full path to file_of_accessions file when provided by the user
    fi

    if [ "$singularity_image" = "" ]
        then
            echo "No singularity image entered, please enter the full path to a singularity image for this script. This is typically hardcoded in the .sh script but can be manually overridden using the -s PATH"
    exit 1
    fi

queue_project="$root_project" # what account to use in the.slurm script this might be differnt from the root dir
blast_cpu="24"
blast_para="-max_target_seqs 10 -num_threads $cpu -mt_mode 1 -evalue 1E-10 -subject_besthit -outfmt '6 qseqid qlen sacc salltitles staxids pident length evalue'"


#lets work out how many jobs we need from the length of input and format the J phrase for the.slurm script
jMax=$(wc -l < $file_of_accessions)
jIndex=$(expr $jMax - 1)
jPhrase="0-""$jIndex"

# if input is of length 1 this will result in an error as J will equal 0-0. We will do a dirty fix and run it as 0-1 which will create an empty second job that will fail.
if [ "$jPhrase" == "0-0" ]; then
    export jPhrase="0-1"
fi

sbatch --array $jPhrase \
    --output "/scratch/director2187/$user/$root_project/$project/logs/blastnt_$SLURM_ARRAY_TASK_ID_$project_$queue_$db_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/director2187/$user/$root_project/$project/logs/blastnt_$SLURM_ARRAY_TASK_ID_$project_$queue_$db_$(date '+%Y%m%d')_stderr.txt" \
    --export="project=$project,file_of_accessions=$file_of_accessions,root_project=$root_project,blast_para=$blast_para,cpu=$cpu,db=$db,singularity_image=$singularity_image" \
    --time "$job_time" \
    --time "$cpu" \
    --time "$mem" \
    --account="$root_project" \
    /scratch/director2187/$user/"$root_project"/"$project"/scripts/JCOM_pipeline_blastnt.slurm