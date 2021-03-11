#! /usr/bin/env python3

from urllib.request import urlopen
from argparse import ArgumentParser
from typing import Optional
import json
import os

def main():
    """
    Given a pace-neutrons repository and branch,
    prints the job name and build number
    """
    parser = ArgumentParser()
    parser.add_argument('repo', type=str,
        help='Name of pace-neutrons repo to query')
    parser.add_argument('branch', type=str,
        help='Branch of repo to query')
    parser.add_argument('--match-context', type=str,
        help=('If given looks for a substring match '
              'in status.context, otherwise just uses '
              'the first status'))

    args = parser.parse_args()
    job_name, build_num = get_build_info_from_status(
        args.repo, args.branch, args.match_context)
    print(f'{job_name} {build_num}')

def get_build_info_from_status(repo: str, branch: str,
                               match_context: Optional[str] = None):
  """
  For a specific pace-neutrons Github repository and branch, query
  the latest commit status to get the latest build URL, and extract
  the build number.

  If match_context, looks at statuses.context for a matching substring
  to get the correct build type. Otherwise just uses the first status.
  """
  status_url = (f'https://api.github.com/repos/pace-neutrons/'
                f'{repo}/commits/{branch}/status')

  with urlopen(status_url) as response:
    content = response.read()
  response_json = json.loads(content)

  status_idx = -1
  if match_context is not None:
      for i, status in enumerate(response_json['statuses']):
          if match_context in status['context']:
              status_idx = i
              break
      if status_idx == -1:
          raise RuntimeError(
              (f"Couldn't find context {match_context} in "
               f"statuses.context at {status_url}"))
  else:
      status_idx = 0

  build_url = response_json['statuses'][status_idx]['target_url']
  job_name = build_url.split('/')[-3]
  build_num = build_url.split('/')[-2]
  return job_name, build_num

if __name__ == '__main__':
    main()
