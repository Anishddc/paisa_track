import os
import requests

# Create animations directory if it doesn't exist
os.makedirs('paisa_track/assets/animations', exist_ok=True)

# Animation URLs from LottieFiles (financial-themed animations)
animations = {
    'welcome.json': 'https://assets2.lottiefiles.com/packages/lf20_rhnmhzwj.json',  # Finance app intro
    'expenses.json': 'https://assets5.lottiefiles.com/packages/lf20_q5pk6p1k.json',  # Money management
    'goals.json': 'https://assets2.lottiefiles.com/private_files/lf30_F6EtR5.json',  # Goal achievement
    'security.json': 'https://assets8.lottiefiles.com/packages/lf20_8qtloeuv.json',  # Security shield
    'get_started.json': 'https://assets6.lottiefiles.com/packages/lf20_vvmGOvFz1S.json'  # Success/completion
}

def download_animation(filename, url):
    print(f'Downloading {filename}...')
    response = requests.get(url)
    if response.status_code == 200:
        with open(f'paisa_track/assets/animations/{filename}', 'wb') as f:
            f.write(response.content)
        print(f'Successfully downloaded {filename}')
    else:
        print(f'Failed to download {filename}: {response.status_code}')

def main():
    for filename, url in animations.items():
        download_animation(filename, url)

if __name__ == '__main__':
    main() 