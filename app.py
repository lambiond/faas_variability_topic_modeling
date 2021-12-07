from datetime import datetime
from Inspector import Inspector
import topic_model
import json
import logging
import s3

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
    if results['newcontainer'] == 0:
        state="warm"
    else:
        state="cold"
    # format a filename
    dt = dt.strftime('%Y%m%d_%H%M%S')
    filename = f"{dt}-{state}-{results['functionName']}-{results['functionRegion']}.txt"
    s3.s3_upload_object(bytes(json.dumps(results).encode('UTF-8')), 'tcss562-x86-results', filename)
    return results
