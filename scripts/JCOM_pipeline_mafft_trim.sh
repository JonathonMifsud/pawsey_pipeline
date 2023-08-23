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

while getopts "i:r:" 'OPTKEY'; do
    case "$OPTKEY" in
            'i')
                # 
                sequences="$OPTARG"
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

    if [ "$sequences" = "" ]
        then
            echo "No sequences provided to align use -i myseqs.fasta" 
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
    
sbatch --output="/scratch/director2187/$user/$root_project/$project/logs/mafft_alignment_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/director2187/$user/$root_project/$project/logs/mafft_alignment_$(date '+%Y%m%d')_stderr.txt" \
    --export="sequences=$sequences" \
    --time "$job_time" \
    --account="$root_project" \
   /scratch/director2187/$user/$root_project/$project/scripts/JCOM_pipeline_mafft_trim.pbs