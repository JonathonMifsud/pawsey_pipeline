#!/bin/bash
###############################################################################################################
#                                            BatchArtemisSRAMiner                                             #
#                                                JCO Mifsud                                                   #
#                                                   2023                                                      #
#                                                                                                             #
###############################################################################################################

# shell wrapper script to run iqtree
# provide an alignment
model="MFP"

# Set the default values
user=jmif9945
project="JCOM_pipeline_virome"
root_project="jcomvirome"
account="director2187"
singularity_image="/scratch/$account/jmif9945/modules/iqtree:v1.6.9dfsg-1.sif"

while getopts "i:m:r:p:s:" 'OPTKEY'; do
    case "$OPTKEY" in
            'i')
                # 
                alignment="$OPTARG"
                ;;
            'm')
                # 
                model="$OPTARG"
                ;;
            'r')
                #
                root_project="$OPTARG"
                ;;
            'p')
                # 
                project="$OPTARG"
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

    if [ "$alignment" = "" ]
        then
            echo "No alignment provided to align use -i myseqs.fasta" 
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

    if [ "$singularity_image" = "" ]
        then
            echo "No singularity image entered, please enter the full path to a singularity image for this script. This is typically hardcoded in the .sh script but can be manually overridden using the -s PATH"
    exit 1
    fi
    
sbatch --output="/scratch/$account/$user/$root_project/$project/logs/iqtree_$(date '+%Y%m%d')_stout.txt" \
    --error="/scratch/$account/$user/$root_project/$project/logs/iqtree_$(date '+%Y%m%d')_stderr.txt" \
    --export="alignment=$alignment,model=$model,project=$project,root_project=$root_project,singularity_image=$singularity_image,account=$account,user=$user" \
    --time "12:00:00" \
    --account="$account" \
    /scratch/$account/$user/$root_project/$project/scripts/JCOM_pipeline_iqtree.slurm
