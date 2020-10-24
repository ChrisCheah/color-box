
#Docker Essentials for Python Developers
https://intel.udemy.com/course/docker-essentials-for-python-developers/learn/lecture/17259344#notes

# Getting Started
[ [Linux](GettingStartedLinux) ]
## Setting Up
```
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv env
env\Scripts\activate.bat
```
## Build & Run
```
pip install -r requirements.txt
set FLASK_APP=color-boxes.py
python -m flask run -port 5001
```

## Run (Powershell)
```
python -m flask run --port 5002
```

## Build & Run on Docker
```
docker build -t myflask/color-boxes:0.1 .  
docker run -p 5000:5000 myflask/color-boxes:0.1
```
## Deploy to Azure
Source: https://docs.microsoft.com/en-us/azure/app-service/quickstart-python?tabs=bash&pivots=python-framework-flask 
```
az webapp up --sku F1 --name intc-color-box-demo1
```

## Deploy to Heroku
Source: https://devcenter.heroku.com/articles/getting-started-with-python

### Define a Procfile
Use a Procfile, a text file in the root directory with the following content
```
web: gunicorn color-box.wsgi --log-file -
```

Steps
```
heroku craete
git push heroku master
heroku ps:scale web=1
heroku open
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