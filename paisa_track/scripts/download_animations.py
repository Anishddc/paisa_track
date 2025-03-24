import os
import requests
import json

# Create animations directory if it doesn't exist
os.makedirs('assets/animations', exist_ok=True)

# Animation URLs from LottieFiles
animations = {
    'money_tracking.json': 'https://assets2.lottiefiles.com/packages/lf20_2cwDXD.json',
    'budgeting.json': 'https://assets5.lottiefiles.com/packages/lf20_2cwDXD.json',
    'goals.json': 'https://assets9.lottiefiles.com/packages/lf20_2cwDXD.json',
    'security.json': 'https://assets10.lottiefiles.com/packages/lf20_2cwDXD.json',
    'get_started.json': 'https://assets3.lottiefiles.com/packages/lf20_2cwDXD.json',
}

def download_animation(filename, url):
    print(f'Downloading {filename}...')
    response = requests.get(url)
    if response.status_code == 200:
        with open(f'assets/animations/{filename}', 'wb') as f:
            f.write(response.content)
        print(f'Successfully downloaded {filename}')
    else:
        print(f'Failed to download {filename}: {response.status_code}')

def main():
    for filename, url in animations.items():
        download_animation(filename, url)

if __name__ == '__main__':
    main() 