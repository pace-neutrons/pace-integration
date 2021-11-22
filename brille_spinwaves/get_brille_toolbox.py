import requests, json

def get_release_tbx(url):
    response = requests.get(url)
    if response.status_code != 200:
        raise RuntimeError('Could not query Github if release exists')
    response = json.loads(response.text)
    # Latest release is always the first entry
    tbx = [v for v in response[0]['assets'] if v['name'].endswith('mltbx')][0]
    return tbx

def download_github(gh_response):
    headers = {"Accept":"application/octet-stream"}
    filename = gh_response['name']
    url = gh_response['url']
    with requests.get(url, stream=True, headers=headers) as r:
        with open(filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    return filename

if __name__ == '__main__':
    tbx = get_release_tbx('https://api.github.com/repos/brille/brillem/releases')
    download_github(tbx)
