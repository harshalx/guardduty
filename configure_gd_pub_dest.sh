
#!/bin/sh

DETECTOR_ID=$1
ARN_S3_BUCKET=$2
ARN_KEY=$3
ROLE_ARN=$4

# Assume security account role OrganizationAccountAccessRole
#aws sts assume-role --role-arn $ROLE_ARN --role-session-name test --duration-seconds 900 > /tmp/creds

#export AWS_ACCESS_KEY_ID=`cat /tmp/creds | jq .Credentials.AccessKeyId | sed 's/\"//g'`
#export AWS_REGION=eu-west-1
#export AWS_SECRET_ACCESS_KEY=`cat /tmp/creds | jq .Credentials.SecretAccessKey | sed 's/\"//g'`
#export AWS_SESSION_TOKEN=`cat /tmp/creds | jq .Credentials.SessionToken | sed 's/\"//g'`
#export AWS_SECURITY_TOKEN=`cat /tmp/creds | jq .Credentials.SessionToken | sed 's/\"//g'`

aws guardduty list-publishing-destinations --detector-id $DETECTOR_ID | grep DestinationId
retVal=`echo $?`
if [ "$retVal" = "1" ]
then 
	aws guardduty create-publishing-destination --detector-id $DETECTOR_ID --destination-type S3 --destination-properties "DestinationArn=$ARN_S3_BUCKET,KmsKeyArn=$ARN_KEY"
else
	echo "Destination already exists"
fi

