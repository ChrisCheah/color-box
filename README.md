
#Docker Essentials for Python Developers
https://intel.udemy.com/course/docker-essentials-for-python-developers/learn/lecture/17259344#notes

# color box
## Setting Up
```
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv color-box/env
env\Scripts\activate.bat
```

## Build & Run (Powershell)
```
pip install -r requirements.txt
$env:FLASK_APP = "color-boxes.py"
python -m flask run
```

## Build & Run on Docker
```
docker build -t myflask/color-boxes:0.1 .  
docker run -p 5001:5001 myflask/color-boxes:0.1  
```
