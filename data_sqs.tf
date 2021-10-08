data "aws_sqs_queue" "s3_notification_queue" {
	provider = aws.ume-core-security
	name = var.bucket_event_notification_queue_name
}