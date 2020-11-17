
# Getting Started
[Main](README)
## Read this

## Setting Up
When using Windows WSL, git clone the following into the home directory [Source](https://stackoverflow.com/questions/61596003/pip3-is-unable-to-create-virtual-environment-on-ubuntu-20-04-lts-on-windows-10-b)   


```
cd ~/
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv env
source env/bin/activate
```

## Build & Run with gunicorn (Linux)
```
pip install -r requirements.txt
gunicorn --bind 0.0.0.0:5000 wsgi:app
```