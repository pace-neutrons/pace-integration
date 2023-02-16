#! /usr/bin/env python3

from argparse import ArgumentParser
from typing import Optional
from utils import get_response_json

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
  commits_url = (f'https://api.github.com/repos/pace-neutrons/'
                 f'{repo}/commits?sha={branch}')
  commits_json = get_response_json(commits_url)

  max_commits = 10  # Only search last 10 commits for a successful build
  build_url = None
  for i in range(max_commits):
      commit_sha = commits_json[i]['sha']
      status_url = (f'https://api.github.com/repos/pace-neutrons/'
                    f'{repo}/commits/{commit_sha}/status')
      print(f'Looking at {status_url}')
      status_json = get_response_json(status_url)

      for status in status_json['statuses']:
          if match_context is not None:
              if match_context in status['context']:
                  build_url = status['target_url']
                  break
          else:
              build_url = status['target_url']
              break
      if build_url is not None:
          break

  if build_url is None:
      if match_context:
          match_str = f'matching {match_context} '
      else:
          match_str = ''
      raise RuntimeError(
          (f"Couldn't find build url {match_str}in "
           f"statuses {commits_url}"))

  job_name = build_url.split('/')[-3]
  build_num = build_url.split('/')[-2]
  return job_name, build_num

if __name__ == '__main__':
    main()
