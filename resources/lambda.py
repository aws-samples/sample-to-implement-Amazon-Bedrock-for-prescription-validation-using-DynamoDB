import json
import boto3
import time
from botocore.exceptions import ClientError
import os 

TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']

def get_patient_medications(client, table_name, patient_id):
    """Get patient's current medications"""
    try:
        response = client.query(
            TableName=table_name,
            KeyConditionExpression='PatientID = :pid',
            ExpressionAttributeValues={
                ':pid': {'S': patient_id}
            },
            ConsistentRead=True  # Ensures we get the most up-to-date data
        )
        return response
    except ClientError as e:
        print(f"Error getting patient medications: {str(e)}")
        raise

def record_interaction_check(client, table_name, patient_id, med_name, check_details):
    """Record new interaction check in the existing medication record"""
    try:
        check_id = f"IC-{int(time.time())}"
        response = client.update_item(
            TableName=table_name,
            Key={
                'PatientID': {'S': patient_id},
                'Medication': {'S': med_name}
            },
            UpdateExpression='SET InteractionChecks = list_append(if_not_exists(InteractionChecks, :empty_list), :new_check)',
            ExpressionAttributeValues={
                ':empty_list': {'L': []},
                ':new_check': {'L': [{
                    'M': {
                        'CheckID': {'S': check_id},
                        'Timestamp': {'S': check_details['timestamp']},
                        'ProposedMedication': {'S': check_details['proposed_med']},
                        'Result': {'S': check_details['result']},
                        'Details': {'S': check_details['details']}
                    }
                }]}
            }
        )
        return response
    except ClientError as e:
        print(f"Error recording interaction check: {str(e)}")
        raise

def lambda_handler(event, context):
    """Lambda handler for prescription interaction checking"""
    try:
        print(f"Input from agent: {event}")
        client = boto3.client('dynamodb')
        table_name = os.environ['DYNAMODB_TABLE_NAME']

        if event['httpMethod'] == 'GET':
            # Extract patientId from parameters
            patient_id = None
            for param in event['parameters']:
                if param['name'] == 'patientId':
                    patient_id = param['value']
                    break
            
            if not patient_id:
                raise ValueError("Missing patient ID")

            response = get_patient_medications(client, table_name, patient_id)
            
            if not response.get('Items'):
                response_body = {
                    'application/json': {
                        'body': json.dumps({
                            'status': 'NOT_FOUND',
                            'message': f"No medications found for patient: {patient_id}"
                        })
                    }
                }
            else:
                response_body = {
                    'application/json': {
                        'body': json.dumps({
                            'status': 'SUCCESS',
                            'patientId': patient_id,
                            'currentMedications': [
                                {
                                    'name': item['Medication']['S'],
                                    'dosage': item.get('Dosage', {}).get('S', ''),
                                    'frequency': item.get('Frequency', {}).get('S', ''),
                                    'interactionChecks': [
                                        {
                                            'checkId': check['M']['CheckID']['S'],
                                            'timestamp': check['M']['Timestamp']['S'],
                                            'proposedMed': check['M']['ProposedMedication']['S'],
                                            'result': check['M']['Result']['S'],
                                            'details': check['M']['Details']['S']
                                        }
                                        for check in item.get('InteractionChecks', {}).get('L', [])
                                    ]
                                }
                                for item in response['Items']
                            ]
                        })
                    }
                }

        elif event['httpMethod'] == 'POST':
            # Extract patientId from parameters
            patient_id = None
            for param in event['parameters']:
                if param['name'] == 'patientId':
                    patient_id = param['value']
                    break

            if not patient_id:
                raise ValueError("Missing patient ID")

            # Extract proposed medication
            proposed_med = None
            request_properties = event['requestBody']['content']['application/json']['properties']
            for prop in request_properties:
                if prop['name'] == 'proposed_medication':
                    proposed_med = prop['value']
                    break

            if not proposed_med:
                raise ValueError("Missing proposed medication")

            # Get current medications to update
            response = get_patient_medications(client, table_name, patient_id)
            if not response.get('Items'):
                raise ValueError(f"No medications found for patient: {patient_id}")

            # Create check details
            check_details = {
                'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                'proposed_med': proposed_med,
                'result': 'CHECKED',
                'details': 'Interaction check completed'
            }

            # Record the interaction check for each current medication
            for item in response['Items']:
                current_med = item['Medication']['S']
                record_interaction_check(
                    client,
                    table_name,
                    patient_id,
                    current_med,
                    check_details
                )

            response_body = {
                'application/json': {
                    'body': json.dumps({
                        'status': 'SUCCESS',
                        'message': f"Recorded interaction checks for patient {patient_id} with {proposed_med}",
                        'checkDetails': check_details
                    })
                }
            }
        else:
            raise ValueError(f"Unsupported HTTP method: {event['httpMethod']}")

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        response_body = {
            'application/json': {
                'body': json.dumps({
                    'status': 'ERROR',
                    'message': f"Error processing request: {str(e)}"
                })
            }
        }

    action_response = {
        'actionGroup': event.get('actionGroup', ''),
        'apiPath': event.get('apiPath', ''),
        'httpMethod': event.get('httpMethod', ''),
        'httpStatusCode': 200,
        'responseBody': response_body
    }

    return {
        'messageVersion': '1.0',
        'response': action_response,
        'sessionAttributes': event.get('sessionAttributes', {}),
        'promptSessionAttributes': event.get('promptSessionAttributes', {})
    }
