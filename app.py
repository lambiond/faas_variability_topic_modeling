from datetime import datetime
from Inspector import Inspector
import topic_model
import json
import logging
import s3
import platform

def handler(event, context):
    # Collect data
    inspector = Inspector()
    inspector.inspectAll()
    # Add custom message and finish the function
    dt =  datetime.now()
    inspector.addAttribute("datetime", dt.strftime("%d/%m/%Y %H:%M:%S"))
    topic_model.run[event['function_name']]()

    inspector.inspectAllDeltas()
    results = inspector.finish()
    # If newcontainer is 0 then we have a warm start, otherwise cold start
    if results['newcontainer'] == 0:
        state="warm"
    else:
        state="cold"

    # Determine CPU arch for S3 buckets
    if platform.machine() == 'x86_64':
        arch = 'x86'
    else:
        arch = 'arm'

    # format a filename
    dt = dt.strftime('%Y%m%d_%H%M%S')
    filename = f"{dt}-{state}-{event['function_name']}-{results['functionRegion']}.txt"

    s3.s3_upload_object(bytes(json.dumps(results).encode('UTF-8')), f'tcss562-{arch}-results', filename)
    return results
