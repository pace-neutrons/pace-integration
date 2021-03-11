from urllib.request import urlopen
from argparse import ArgumentParser
import json
import os

def main():
    parser = ArgumentParser()
    parser.add_argument('repo', type=str,
        help='Name of pace-neutrons repo to query')
    parser.add_argument('branch', type=str,
        help='Branch of repo to query')
    parser.add_argument('--match-build', action='store_true',
        help=('Matches the build given by the PLATFORM and '
              'MATLAB_VERSION environment variables to the '
              'status.context string'))

    args = parser.parse_args()
    print(get_build_num(args.repo, args.branch, args.match_build))

def get_build_num(repo: str, branch: str,
                  match_build: bool = False):
  """
  For a specific pace-neutrons Github repository and branch, query
  the latest commit status to get the latest build URL, and extract
  the build number.

  If match_build, then uses the PLATFORM and MATLAB_VERSION environment
  variables to look at statuses.context to get the correct build type.
  Otherwise just uses the first status.
  """
  status_url = (f'https://api.github.com/repos/pace-neutrons/'
                f'{repo}/commits/{branch}/status')

  with urlopen(status_url) as response:
    content = response.read()
  response_json = json.loads(content)

  status_idx = -1
  if match_build:
      platform = os.environ['PLATFORM']
      matlab_ver = os.environ['MATLAB_VERSION']
      match_build_str = platform + '-' + matlab_ver 
      for i, status in enumerate(response_json['statuses']):
          if match_build_str in status['context']:
              status_idx = i
              break
      if status_idx == -1:
          raise RuntimeError(
              (f"Couldn't find build {match_build_str} in "
               f"statuses.context at {status_url}"))
  else:
      status_idx = 0

  build_url = response_json['statuses'][status_idx]['target_url']
  build_num = build_url.split('/')[-2]
  return build_num

if __name__ == '__main__':
    main()
