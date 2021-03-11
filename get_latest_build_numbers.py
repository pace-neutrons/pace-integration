from urllib.request import urlopen
import json
import os

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
  print(status_url)

  with urlopen(status_url) as response:
    content = response.read()
  response_json = json.loads(content)
  print(response_json)

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
                "statuses.context at {status_url}"))
  else:
      status_idx = 0

  build_url = response_json['statuses'][status_idx]['target_url']
  build_num = build_url.split('/')[-2]
  return build_num

hor_eu_if_num = get_build_num(
    'horace-euphonic-interface',
    os.environ['HORACE_EUPHONIC_INTERFACE_BRANCH'])
os.environ['HORACE_EUPHONIC_INTERFACE_BUILD_NUM'] = hor_eu_if_num

horace_branch = os.environ['HORACE_BRANCH']
if horace_branch != 'master':
    horace_num = get_build_num(
        'Horace', horace_branch, match_build=True)
    os.environ['HORACE_BUILD_NUM'] = horace_num
