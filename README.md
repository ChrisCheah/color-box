
#Docker Essentials for Python Developers
https://intel.udemy.com/course/docker-essentials-for-python-developers/learn/lecture/17259344#notes

# color box
## Setting Up
```
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv env
```

### activate env (Windows)
```
env\Scripts\activate.bat
```
### activate env (Linux)
```
source env/bin/activate
```

## Build & Run
```
pip install -r requirements.txt
```


## Run (Windows CMD)
```
set FLASK_APP=color-boxes.py
python -m flask run -port 5001
```

## Run (Powershell)
```
python -m flask run --port 5002
```

## Run with gunicorn (Linux)
```
gunicorn --bind 0.0.0.0:5000 wsgi:app
```

## Build & Run on Docker
```
docker build -t myflask/color-boxes:0.1 .  
docker run -p 5000:5000 myflask/color-boxes:0.1
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

## Deploy to IBM Cloud / Cloud Foundry
### Define a manifest file
Add manifest.yml in the root directory with the following content
```
---
version: 1
applications:
    - name: color-boxes
      random-route: true
      memory: 64M
      buildpacks: 
        - https://github.com/cloudfoundry/python-buildpack.git
```

Steps
```
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