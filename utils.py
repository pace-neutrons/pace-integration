import os
import requests
import warnings

def get_response_json(url):
    if os.environ.get('api_token'):
        header = {'Authorization': 'token ' + os.environ['api_token']}
    else:
        header = None
        warnings.warn(f'Not authenticating request for {url}')

    response = requests.get(url, headers=header)
    response.raise_for_status()
    return response.json()
