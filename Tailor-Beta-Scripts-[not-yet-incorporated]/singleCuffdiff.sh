#!/bin/bash

#--------------------------------------------------------------------------------------------------------------
# singleCuffdiff - find significant changes in transcript expression, splicing, and promoter use
#
#   - Run Cuffdiff by using the merged transcriptome assembly along with the BAM files from TopHat for each replicate
#
#   - The default is to use EdgeR parameters (?)
#
#   - Can send you emails when each job starts to execute and when each is finished so
#    that you know when to submit the jobs for the next step
#
#--------------------------------------------------------------------------------------------------------------

#----SETTINGS---------------
source "${TAILOR_CONFIG}"
#---------------------------

#----COMMAND LINE ARGUMENTS-----------------------------------------------------------
readarray -t experiment1Group < $1   # read in all replicates, -t strips newlines
experiment1Name=$2

readarray -t experiment2Group < $3   # read in all replicates, -t strips newlines
experiment2Name=$4
#-------------------------------------------------------------------------------------

#----JOB SUBMISSION PARAMETERS---------------------------------------------------------------------
PROCESSORS=7
MEMORY="7036"      # PER PROCESSOR!! - 2048=2G, 4096=4G, 8192=8G, 16384=16G, 32768=32G, 65536=64G
DURATION="24:00"   # HH:MM - 72:00=3 days, 96:00=4 days, 192:00=8 days, 384:00=16 days, 768:00=32 days
QUEUE="long"        # short = max 4 hours;   long = max 30 days
#--------------------------------------------------------------------------------------------------

#----PATHS-----------------------------------------------------------------------------------------
INPUT_GTF="${CUFFDIFF_INPUT_GTF}"
INPUT_ALIGNMENTS="${CUFFDIFF_INPUT_ALIGNMENTS}"
OUTPUT="${CUFFDIFF_OUTPUT}"
SCRIPTS=${OUTPUT}/${JOBS_SCRIPTS_DIR}
JOBS=${OUTPUT}/${JOBS_OUT_DIR}
#--------------------------------------------------------------------------------------------------

#----OUTPUT------------------
if [ ! -d ${OUTPUT} ]; then
    mkdir ${OUTPUT}
fi
if [ ! -d ${SCRIPTS} ]; then
    mkdir ${SCRIPTS}
fi
if [ ! -d ${JOBS} ]; then
    mkdir ${JOBS}
fi
#----------------------------

COMMAND=cuffdiff
FOLD_CHANGE=$(eval echo $CUFFDIFF_FOLDCHANGE_OUTPUT)

#-------------------------------------------------------------------
# Create a list of all the BAM files for the 2 experiments
#-------------------------------------------------------------------

echo -e "\nGroup 1 size is ${#experiment1Group[@]}"
echo -e "\nGroup 1 is (${experiment1Group[@]})"
echo -e "\nGroup 2 size is ${#experiment2Group[@]}"
echo -e "\nGroup 2 is (${experiment2Group[@]})"

experiment1Files=""
experiment2Files=""

# ${!array[*]} gives indicies
# ${#array[@]} gives the length

for i in ${!experiment1Group[*]}
do
    # append a comma if necessary
    if [ $i -gt 0 ]
    then
	experiment1Files+=","
    fi
    experiment1Files+="${INPUT_ALIGNMENTS}/${experiment1Group[$i]}_out/${CUFFDIFF_ALIGNMENT_FILE}"
done


for i in ${!experiment2Group[*]}
do
    # append a comma if necessary
    if [ $i -gt 0 ]
    then
	experiment2Files+=","
    fi
    experiment2Files+="${INPUT_ALIGNMENTS}/${experiment2Group[$i]}_out/${CUFFDIFF_ALIGNMENT_FILE}"
done

#--------------------------------------------------------------------


EXTRA_PARAMETERS=$(eval echo "$EXTRA_CUFFDIFF_PARAMETERS")
echo -e "\n${EXTRA_PARAMETERS}"

COMMAND_LINE="${COMMAND} -p ${PROCESSORS} ${EXTRA_PARAMETERS} -o ${OUTPUT}/${FOLD_CHANGE} ${INPUT_GTF} $experiment1Files $experiment2Files"

scriptString="mktemp -p ${SCRIPTS} -t ${COMMAND}.${FOLD_CHANGE}.XXXXXXXXXXX"
echo -e "\n${scriptString}"
tempScript=`${scriptString}`
echo -e "\n${tempScript}"
chmod=`chmod 777 ${tempScript}`
chmodString="chmod 777 ${tempScript}"
echo -e `${chmodString}`

echo -e "source loadModules.sh\n\n" > ${tempScript}
echo "$COMMAND_LINE" >> ${tempScript}


if [ $SCHEDULER == "sge" ]; then
    SUBMIT_COMMAND="qsub -q $QUEUE -cwd -S /bin/bash -N ${FOLD_CHANGE} -pe smp ${PROCESSORS} -l h_rt=${DURATION},s_rt=${DURATION},vf=${MEMORY} -m eas -M ${USER_EMAIL} ${tempScript}"
else
    SUBMIT_COMMAND="bsub -q $QUEUE -J ${FOLD_CHANGE}.${COMMAND} -n ${PROCESSORS} -R model==Intel_EM64T -R span[hosts=1] -R rusage[mem=${MEMORY}] -W ${DURATION} -u ${LSB_MAILTO} -B -o ${JOBS}/${COMMAND}.${FOLD_CHANGE}.%J.out -e ${JOBS}/${COMMAND}.${FOLD_CHANGE}.%J.error bash ${tempScript}"
fi

date=`date`
echo -e "\n# $date\n"      >> ${OUTPUT}/${COMMAND}.jobs.log
echo -e "\n# Job Script\n" >> ${OUTPUT}/${COMMAND}.jobs.log
cat ${tempScript}          >> ${OUTPUT}/${COMMAND}.jobs.log
echo -e "\n# Job Submission\n${SUBMIT_COMMAND}\n" >> ${OUTPUT}/${COMMAND}.jobs.log
echo -e "\n#-------------------------------------------------------------------------------------------------------" >> ${OUTPUT}/${COMMAND}.jobs.log

echo `${SUBMIT_COMMAND}`
# rm ${tempScript}



