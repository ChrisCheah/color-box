
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

## Run (Powershell)
``` shell
python -m flask run --port 5002
```

## Build & Run on Docker
``` shell
docker build -t myflask/color-boxes:0.1 .  
docker run -p 5000:5000 myflask/color-boxes:0.1
```
## Deploy to Azure
Source: https://docs.microsoft.com/en-us/azure/app-service/quickstart-python?tabs=bash&pivots=python-framework-flask 
``` shell
az webapp up --sku F1 --name intc-color-box-demo1
```

## Deploy to Heroku
Source: https://devcenter.heroku.com/articles/getting-started-with-python

### Define a Procfile
Use a Procfile, a text file in the root directory with the following content
``` shell
web: gunicorn color-box.wsgi --log-file -
```

### Steps
``` shell
heroku craete
git push heroku master
heroku ps:scale web=1
heroku open
```

## Deploy to IBM Cloud / Cloud Foundry
Cloud Foundry cli for python fail to build in Windows cmd. Run this in a Linux environment. The following was done in Windows 10 WSL2 Ubuntu 20
### Pre-requisite
IBM Cloud account with Cloud Foundry Org & Space setup in the selected Region.
1. Install ibmcloud cli
2. Logon and verify that 'ibmcloud target' return valid setup.

### Define a manifest file
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
ibmcloud cf push
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