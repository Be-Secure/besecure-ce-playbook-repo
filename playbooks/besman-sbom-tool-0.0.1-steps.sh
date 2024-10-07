#!/bin/bash
echo "Running $ASSESSMENT_TOOL_NAME"
cd "$BESMAN_TOOL_PATH" || return 1
mkdir $HOME/SBOMOUTPUT
chmod +x $BESMAN_TOOL_PATH/sbom-tool
./sbom-tool generate -b $HOME/SBOMOUTPUT -bc $BESMAN_ARTIFACT_DIR -pn $BESMAN_ARTIFACT_NAME -pv $BESMAN_ARTIFACT_VERSION -nsb $BESMAN_ARTIFACT_URL -ps wipro
if [[ "$?" != "0" ]] 
then
    export SBOM_RESULT=1
else
    export SBOM_RESULT=0
fi 