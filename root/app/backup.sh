#!/usr/bin/with-contenv bash
#shellcheck shell=bash disable=SC1008

my_dir="/app"
source /app/common.sh

log_dir=""
log_file=/dev/null

if [[ -n ${EMAIL_SMTP_SERVER} ]] && [[ -n ${EMAIL_TO} ]]; then
    log_dir=$(mktemp -d)
    log_file="${log_dir}"/backup.log
fi

echo ========== Run backup job at "$(date)" ========== | tee "${log_file}"

if operation_in_progress backup; then
    duration=0
    exitcode=127
else
    # Use the scripts pid as the pid for simplicity
    create_backup_pid_file ${$}
    trap remove_backup_pid_file INT TERM EXIT

    /app/delay.sh "${log_file}"

    start=$(date +%s.%N)

    if [[ -n ${PRE_BACKUP_SCRIPT} ]]; then
        if [[ -f ${PRE_BACKUP_SCRIPT} ]]; then
            echo Run pre backup script | tee -a "${log_file}"
            export log_file my_dir # Variables I require in my pre backup script
            sh -c "${PRE_BACKUP_SCRIPT}" | tee -a "${log_file}"
            exitcode=${PIPESTATUS[0]}
        else
            echo Pre backup script defined, but file not found | tee -a "${log_file}"
            # Command not found exit code (https://tldp.org/LDP/abs/html/exitcodes.html)
            exitcode=127
        fi
    else
        # No pre backup script so call it a success
        exitcode=0
    fi

    if [ "${exitcode}" -eq 0 ]; then
        config_dir=/config

        cd ${config_dir} || (echo Folder "${config_dir}" not found; exit 128)

        nice -n "${PRIORITY_LEVEL}" duplicacy "${GLOBAL_OPTIONS}" backup "${BACKUP_OPTIONS}" | tee -a "${log_file}"
        exitcode=${PIPESTATUS[0]}

        if [[ -n ${POST_BACKUP_SCRIPT} ]]; then
            if [[ -f ${POST_BACKUP_SCRIPT} ]]; then
                echo Run post backup script | tee -a "${log_file}"
                export log_file exitcode duration my_dir # Variables I require in my post backup script
                sh -c "${POST_BACKUP_SCRIPT}" | tee -a "${log_file}"
            else
                echo Post backup script defined, but file not found | tee -a "${log_file}"
            fi
        fi
    else
        echo Pre backup script FAILED, code "${exitcode}", | tee -a "${log_file}"
    fi

    duration=$(echo "$(date +%s.%N) - $start" | bc)
fi

if [ "${exitcode}" -eq 0 ]; then
    echo Backup COMPLETED, duration "$(converts "${duration}")" | tee -a "${log_file}"
    subject="duplicacy backup job id \"${hostname}:${SNAPSHOT_ID}\" COMPLETED"
else
    echo Backup FAILED, code "${exitcode}", duration "$(converts "${duration}")" | tee -a "${log_file}"
    subject="duplicacy backup job id \"${hostname}:${SNAPSHOT_ID}\" FAILED"
fi

/app/mailto.sh "${log_dir}" "${subject}"

exit "${exitcode}"
