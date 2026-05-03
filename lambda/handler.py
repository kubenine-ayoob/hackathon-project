import os
import urllib.parse
import urllib.request
import boto3

def handler(event, context):
    main_backend_url = os.environ.get("MAIN_BACKEND_URL")
    if not main_backend_url:
        ssm_param = os.environ.get("MAIN_BACKEND_URL_SSM_PARAM", "/stacknine/main-backend-url")
        ssm = boto3.client("ssm", region_name=os.environ.get("AWS_REGION", "us-east-1"))
        main_backend_url = ssm.get_parameter(
            Name=ssm_param, WithDecryption=False
        )["Parameter"]["Value"]

    for record in event.get("Records", []):
        key    = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        job_id = key.split("/")[0]

        req = urllib.request.Request(
            f"{main_backend_url}/process/{job_id}",
            method="POST",
            data=b"",
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status != 200:
                raise RuntimeError(f"process endpoint returned {resp.status} for job {job_id}")

    return {"status": "ok"}
