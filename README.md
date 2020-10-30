
#Docker Essentials for Python Developers
https://intel.udemy.com/course/docker-essentials-for-python-developers/learn/lecture/17259344#notes

# Getting Started
[ [Linux](GettingStartedLinux) ]
## Setting Up
``` shell
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv env
env\Scripts\activate.bat
```
## Build & Run
``` shell
pip install -r requirements.txt
# $env:FLASK_APP = "color-boxes.py" ## Powershell
set FLASK_APP=color-boxes.py
python -m flask run -port 5001
```

## Deploy To Cloud Foundry
[ [Other Deployment Options](DeploymentOptions) ]   
### Define a manifest file (optional)
Add manifest.yml in the root directory with the following content
``` yaml
---
version: 1
applications:
    - name: color-boxes
      random-route: true
      memory: 64M
      buildpacks: 
        - https://github.com/cloudfoundry/python-buildpack.git
```

### Steps:
``` shell
cf push
```

## Available API
```
GET     '/'                                - returns greetings string
GET     '/box'                             - returns HTML list of boxes with number of balls in them
GET     '/box/<string:color>'              - return number of balls in <color> box
POST    '/box/<string:color>'              - create an empty box painted with <color>
DELETE  '/box/<string:color>'              - remove box painted with <color>
PUT     '/box/<string:color>/<int:balls>'  - update number of <balls> in box painted with <color>
```