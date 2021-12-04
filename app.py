from Inspector import Inspector
import topic_model
import json
import logging
import time

def handler(event, context):
    # Collect data
    inspector = Inspector()
    inspector.inspectAll()
    # Add custom message and finish the function
    #topic_model.run[event['function_name']]()
    inspector.addAttribute("message", topic_model.run[event['function_name']]())

    inspector.inspectAllDeltas()
    return inspector.finish()
