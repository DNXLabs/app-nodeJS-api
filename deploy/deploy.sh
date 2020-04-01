#!/bin/bash

envsubst < task-definition.tpl.json > task-definition.json
echo "Task Definition:"
cat task-definition.json

export TASK_ARN=TASK_ARN_PLACEHOLDER

envsubst < app-spec.tpl.json > app-spec.json
echo "Deploying app-spec:"
cat app-spec.json

echo "Waiting Deployment to complete"
echo "For More Deployment info : https://ap-southeast-2.console.aws.amazon.com/codesuite/codedeploy/deployments/$DEPLOYMENT_ID"

# Update the ECS service to use the updated Task version
aws ecs deploy \
  --service $APP_NAME \
  --task-definition ./task-definition.json \
  --cluster $CLUSTER_NAME \
  --codedeploy-appspec ./app-spec.json \
  --codedeploy-application $CLUSTER_NAME-$APP_NAME \
  --codedeploy-deployment-group $CLUSTER_NAME-$APP_NAME || error=true

#Fail the build if there was an error
if [ $error ]
then 
    exit -1
fi
echo "Deployment completed!"
