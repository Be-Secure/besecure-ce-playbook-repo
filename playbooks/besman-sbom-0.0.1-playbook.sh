#!/bin/bash

# The data for this json should be made available by prep function

# {
#     "schema_version": "0.1.0",
#     "asset": {
#         "type": "$BESMAN_ASSET_TYPE",
#         "name": "$BESMAN_ASSET_NAME",
#         "version": "$BESMAN_ASSET_VERSION", 
#         "url": "$BESMAN_ASSET_URL", 
#         "environment": "$BESMAN_ENV_NAME"
#     },
#     "assessments": [
#         {
#             "tool": {
#                 "name": "$ASSESSMENT_TOOL_NAME",
#                 "type": "$ASSESSMENT_TOOL_TYPE", 
#                 "version": "$ASSESSMENT_TOOL_VERSION",
#                 "playbook": "$ASSESSMENT_TOOL_PLAYBOOK" 
#             },
#             "execution": {
#                 "type": "$BESLAB_OWNER_TYPE",
#                 "id": "$BESLAB_OWNER_NAME", 
#                 "status": "$PLAYBOOK_EXECUTION_STATUS", 
#                 "timestamp": "$EXECUTION_TIMESTAMP",
#                 "duration": "$EXECUTION_DURATION", 
#                 "output_path": "$DETAILED_REPORT_PATH"
#             },
#             "results": [
#                 {
#                     "feature": "",
#                     "aspect": "",
#                     "attribute": "",
#                     "value": 
#                 }
#             ]
#         }

#     ]
# }

function __besman_init()
{
    export ASSESSMENT_TOOL_NAME="$BESLAB_SBOM"
    export ASSESSMENT_TOOL_TYPE="sbom"
    export ASSESSMENT_TOOL_VERSION="$BESLAB_SBOM_VERSION"
    export ASSESSMENT_TOOL_PLAYBOOK="besman-$ASSESSMENT_TOOL_TYPE-$ASSESSMENT_TOOL_VERSION-playbook.sh"

    local var_array=("BESMAN_ASSET_TYPE" "BESMAN_ASSET_NAME" "BESMAN_ASSET_VERSION" "BESMAN_ASSET_URL" "BESMAN_ENV_NAME" "BESMAN_ASSET_DIR" "ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_VERSION" "ASSESSMENT_TOOL_PLAYBOOK" "BESLAB_ASSESSMENT_DATASTORE_DIR" "BESLAB_ARTIFACT_PATH" "BESLAB_REPORT_FORMAT" "BESLAB_ASSESSMENT_DATASTORE_URL" "OSAR_PATH")



    local flag=false
    for var in "${var_array[@]}";
    do
        if [[ ! -v $var ]] 
        then

            echo "$var is not set"
            flag=true 
        fi

    done
    

    local dir_array=("BESLAB_ASSESSMENT_DATASTORE_DIR" "BESLAB_ASSESSMENT_SUMMARY_DATASTORE_DIR")

    for dir in "${dir_array[@]}";
    do
        # Get the value of the variable with the name stored in $dir
        dir_path="${!dir}"

        if [[ ! -d $dir_path ]] 
        then
    
            echo "Could not find $dir_path"
    
            flag=true
    
        fi
    
    done

    [[ ! -f $BESLAB_ARTIFACT_PATH/$BESLAB_SBOM_TOOL ]] && echo "Could not find artifact @ $BESLAB_ARTIFACT_PATH/$BESLAB_SBOM_TOOL" && flag=true

    if [[ $flag == true ]] 
    then
    
        return 1
    
    else
        export SBOM_PATH="$BESLAB_ASSESSMENT_DATASTORE_DIR/$BESMAN_ASSET_NAME/$BESMAN_ASSET_VERSION/sbom"
        export DETAILED_REPORT_PATH="$SBOM_PATH/$BESMAN_ASSET_NAME-$BESMAN_ASSET_VERSION-sbom.$BESLAB_REPORT_FORMAT"
        mkdir -p "$SBOM_PATH"
        export OSAR_PATH="$BESLAB_ASSESSMENT_DATASTORE_DIR/$BESMAN_ASSET_NAME/$BESMAN_ASSET_VERSION/$BESMAN_ASSET_NAME-$BESMAN_ASSET_VERSION-OSAR.json"

        return 0
    
    fi

}

function __besman_execute()
{
    local duration
    echo "Launching steps file"

    SECONDS=0
    source besman-sbom-0.0.1-steps.sh
    duration=$SECONDS

    export EXECUTION_DURATION=$duration
    if [[ $? == 0 ]] 
    then
        
        return 0
        export PLAYBOOK_EXECUTION_STATUS=success
    
    else
        export PLAYBOOK_EXECUTION_STATUS=failure
        return 1
    fi
    
}

function __besman_prepare()
{

    export EXECUTION_TIMESTAMP=$(date)

    mv "$SBOM_PATH"/bom-*.json "$DETAILED_REPORT_PATH"

}

function __besman_publish()
{
    # push code to remote datastore
    echo "1"
}

function __besman_cleanup()
{
    local var_array=("ASSESSMENT_TOOL_NAME" "ASSESSMENT_TOOL_TYPE" "ASSESSMENT_TOOL_PLAYBOOK" "ASSESSMENT_TOOL_VERSION" "OSAR_PATH" "SBOM_PATH" "DETAILED_REPORT_PATH")

    for var in "${var_array[@]}";
    do
        if [[ -v $var ]] 
        then
            unset $var
        fi

    done
}

function __besman_launch()
{
    local flag=1
    
    __besman_init
    flag=$?
    echo "flag=$flag"
    if [[ $flag == 0 ]] 
    then
    
    __besman_execute
    flag=$?
    
    else

    __besman_cleanup
    return
    fi

    if [[ $flag == 0 ]] 
    then
    
    __besman_prepare
    __besman_publish
    __besman_cleanup
    
    else

    __besman_cleanup
    return


    fi
}

