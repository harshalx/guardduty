variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}

variable "bucket_event_notification_queue_name" {
	description = "The name of the s3 notification event queue"
	type = string
}