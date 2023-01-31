#! /usr/bin/env python3

from argparse import ArgumentParser
from typing import Optional
import requests
import json
import os

def main():
    """
    Given a branch of the Horace-Euphonic-Interface repo,
    prints the latest artifact url
    """
    parser = ArgumentParser()
    parser.add_argument('branch', type=str,
        help='Branch of repo to query')
    parser.add_argument('--api-token', type=str,
        help='Github API token', default='')

    args = parser.parse_args()
    url = get_artifact_url(branch=args.branch, api_token=args.api_token)
    print(url)

def get_response_json(url, api_token=''):
    if api_token:
        response = requests.get(url, headers={'Authorization': 'token ' + api_token})
    else:
        response = requests.get(url)
    response.raise_for_status()
    return response.json()

def get_artifact_url(repo: str = 'horace-euphonic-interface',
                     branch: str = 'master',
                     api_token: str = '',
                     workflow_name: str = 'Horace-Euphonic-Interface Tests',
                     artifact_name: str = 'horace_euphonic_interface.mltbx'):
    """
    For a specific pace-neutrons Github repository and branch, query
    the workflows API to get the latest successful build, get the matching
    build artifact and print the artifact download URL.
    """
    base_url = 'https://api.github.com'

    # Get workflow ID
    workflows_url = f'{base_url}/repos/pace-neutrons/{repo}/actions/workflows'
    content = get_response_json(workflows_url, api_token)
    workflow_id = None
    for workflow in content['workflows']:
        if workflow['name'] == workflow_name:
            workflow_id = workflow['id']
            break
    if workflow_id is None:
        raise RuntimeError(f'Workflow with name {workflow_name} '
                           f'couldn\'t be found at {workflows_url}')
  
    # Get matching workflow run id
    workflow_runs_url = f'{workflows_url}/{workflow_id}/runs'
    content = get_response_json(workflow_runs_url, api_token)
    workflow_run_id = None
    for workflow_run in content['workflow_runs']:
        if (workflow_run['status'] == 'completed' and
                workflow_run['conclusion'] == 'success' and
                workflow_run['head_branch'] == branch):
            workflow_run_id = workflow_run['id']
            break
    if workflow_run_id is None:
        raise RuntimeError(f'Successful workflow with branch {branch} '
                           f'couldn\'t be found at {workflow_runs_url}')

    # Get matching artifact
    artifacts_url = (f'{base_url}/repos/pace-neutrons/{repo}/actions/'
                    f'runs/{workflow_run_id}/artifacts')
    content = get_response_json(artifacts_url, api_token)
    artifact_download_url = None
    for artifact in content['artifacts']:    
        if artifact['name'] == artifact_name:
            artifact_download_url = artifact['archive_download_url']
    if artifact_download_url is None:
        raise RuntimeError(f'Artifact with name {artifact_name} '
                           f'couldn\'t be found at {artifacts_url}')
    return artifact_download_url

if __name__ == '__main__':
    main()
