#!/bin/bash

function __besman_init() {
    __besman_echo_white "initialising"
    export ASSESSMENT_TOOL_NAME="bert-prediction"
    export ASSESSMENT_TOOL_TYPE="nlp"
    export ASSESSMENT_TOOL_VERSION="1.0.0"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_NAME-0.0.1-setps.sh"

    local steps_file_name="besman-$ASSESSMENT_TOOL_NAME-0.0.1-steps.ipynb"
    export BESMAN_STEPS_FILE_PATH="$BESMAN_PLAYBOOK_DIR/$steps_file_name"

    local var_array=("BESMAN_ARTIFACT_TYPE" "BESMAN_ARTIFACT_NAME" "BESMAN_ARTIFACT_VERSION" "BESMAN_ARTIFACT_URL" "BESMAN_ENV_NAME" "BESMAN_ARTIFACT_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESMAN_ASSESSMENT_DATASTORE_DIR" "BESMAN_TOOL_PATH" "BESMAN_ASSESSMENT_DATASTORE_URL" "BESMAN_LAB_TYPE" "BESMAN_LAB_NAME")

    local flag=false
    for var in "${var_array[@]}"; do
        if [[ ! -v $var ]]; then
            __besman_echo_yellow "$var is not set"
            __besman_echo_no_colour ""
            flag=true
        fi
    done

    local dir_array=("BESMAN_ASSESSMENT_DATASTORE_DIR")
    for dir in "${dir_array[@]}"; do
        dir_path="${!dir}"
        if [[ ! -d $dir_path ]]; then
            __besman_echo_red "Could not find $dir_path"
            flag=true
        fi
    done

    if [[ -z $(command -v docker) ]]; then
        __besman_echo_red "Docker not installed"
        flag=true
    fi

    if [[ $flag == true ]]; then
        return 1
    else
        export BERT_PATH="$BESMAN_ASSESSMENT_DATASTORE_DIR/$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/$ASSESSMENT_TOOL_TYPE"
        export DETAILED_REPORT_PATH="$BERT_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-report.json"
        mkdir -p "$BERT_PATH"
        export OSAR_PATH="$BERT_PATH/$BESMAN_ARTIFACT_NAME-$BESMAN_ARTIFACT_VERSION-osar.json"
        __besman_fetch_steps_file "$steps_file_name" || return 1
        return 0
    fi
}

function __besman_execute() {
    local duration
    mkdir -p "$BESMAN_DIR/tmp/steps"
    __besman_echo_yellow "Launching steps file"
    cp "$BESMAN_STEPS_FILE_PATH" "$BESMAN_DIR/tmp/steps"
    SECONDS=0
    jupyter notebook "$BESMAN_DIR/tmp/steps"
    duration=$SECONDS

    export EXECUTION_DURATION=$duration
    if [[ ! -f $DETAILED_REPORT_PATH ]]; then
        __besman_echo_red "Could not find detailed report @ $DETAILED_REPORT_PATH"
        export PLAYBOOK_EXECUTION_STATUS=failure
        return 1
    else
        export PLAYBOOK_EXECUTION_STATUS=success
        return 0
    fi
    rm -rf "$BESMAN_DIR/tmp/steps"
}

function __besman_prepare() {
    __besman_echo_white "preparing data"
    EXECUTION_TIMESTAMP=$(date)
    export EXECUTION_TIMESTAMP
    [[ ! -f $DETAILED_REPORT_PATH ]] && __besman_echo_red "Could not find report at $DETAILED_REPORT_PATH" && return 1
    __besman_generate_osar
}

function __besman_publish() {
    __besman_echo_yellow "Pushing to datastores"
    cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    git add "$DETAILED_REPORT_PATH" "$OSAR_PATH"
    git commit -m "Added osar and detailed report"
    git push origin main
}

function __besman_cleanup() {
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "BERT_PATH" "DETAILED_REPORT_PATH")
    for var in "${var_array[@]}"; do
        if [[ -v $var ]]; then
            unset "$var"
        fi
    done
}

function __besman_launch() {
    __besman_echo_yellow "Starting playbook"
    local flag=1

    __besman_init
    flag=$?
    if [[ $flag == 0 ]]; then
        __besman_execute
        flag=$?
    else
        __besman_cleanup
        return
    fi

    if [[ $flag == 0 ]]; then
        __besman_prepare
        __besman_publish
        __besman_cleanup
    else
        __besman_cleanup
        return
    fi
}

function __besman_fetch_steps_file() {
    __besman_echo_white "fetching steps file"
    local steps_file_name=$1
    local steps_file_url="https://raw.githubusercontent.com/$BESMAN_PLAYBOOK_REPO/$BESMAN_PLAYBOOK_REPO_BRANCH/playbooks/$steps_file_name"
    __besman_check_url_valid "$steps_file_url" || return 1

    if [[ ! -f "$BESMAN_STEPS_FILE_PATH" ]]; then
        touch "$BESMAN_STEPS_FILE_PATH"
        __besman_secure_curl "$steps_file_url" >>"$BESMAN_STEPS_FILE_PATH"
        [[ "$?" != "0" ]] && __besman_echo_red "Failed to fetch from $steps_file_url" && return 1
    fi
    __besman_echo_white "done fetching"
}
