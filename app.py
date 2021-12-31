from Inspector import Inspector
import topic_model

def handler(event, context):
    # Collect data
    inspector = Inspector()
    inspector.inspectAll()
    # Add custom message and finish the function
    if "startWallClock" in event:
        inspector.addAttribute("startWallClock", event['startWallClock'])
    topic_model.run[event['function_name']]()

    inspector.inspectAllDeltas()
    # Include lambdaName and functionName
    inspector.addAttribute("lambdaName", inspector.getAttribute('functionName'))
    inspector.addAttribute("functionName", event['function_name'])

    return inspector.finish()
