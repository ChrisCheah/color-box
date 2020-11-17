
# Getting Started
[Main](README.md)
## Setting Up
```
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

## Build & Run on Docker locally
``` shell
docker build -t colorbox:0.1 .  
docker run -p 5000:5000 colorbox:0.1
```

## Deploy to Docker hub
Create repo 'colorbox' in Docker hub
``` shell
docker login
# docker build -t cheahyc/colorbox:0.1 .  
docker tag colorbox:0.1 cheahyc/colorbox:0.1
docker push cheahyc/colorbox:0.1
```

## Deploy to Intel Docker Registry
Registry: https://amr-registry-pre.caas.intel.com/
Project: ditwebapp

``` shell
docker login https://amr-registry-pre.caas.intel.com
docker tag colorbox:0.1 amr-registry-pre.caas.intel.com/ditwebapp/colorbox:0.1
docker push amr-registry-pre.caas.intel.com/ditwebapp/colorbox:0.1
```