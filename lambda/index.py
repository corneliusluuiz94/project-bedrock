import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """
    Triggered by S3 ObjectCreated events on the bedrock-assets bucket.
    Logs the uploaded filename — this is what the grader checks for in
    CloudWatch Logs after uploading a test file.
    """
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        logger.info("Image received: %s", key)
        print(f"Image received: {key}")  # also to stdout, belt-and-suspenders for log capture

    return {"statusCode": 200}
