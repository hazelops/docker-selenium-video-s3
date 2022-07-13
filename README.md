# Selenium Video S3 Docker Image

This image is based on the official selenium-video image, but it adds aws cli and logic to upload sessions to s3.
## Parameters
- S3_BUCKET_NAME (required)
- CUSTOM_TAG_NAME
## Custom Data
It also reads custom data, if passed via user-data-dir. 
For instance in python you could do something like this:
```shell
chrome_options.add_argument("--user-data-dir=/tmp/selenium.test_id=12345,ticket_id=TST-111,commit_id=4h68dc45b")
```

Your video file name would be `test_id=12345,ticket_id=TST-111,commit_id=4h68dc45b.video.mp4`

Mildly tested with Chrome, ECS and Fargate. Has some hardcoded stuff, will be fixed in a bit.

Use it at your own risk
