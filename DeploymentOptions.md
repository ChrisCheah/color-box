# Getting Started
[Main](README)

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

## Deploy to Azure
Source: https://docs.microsoft.com/en-us/azure/app-service/quickstart-python?tabs=bash&pivots=python-framework-flask 
``` shell
az webapp up --sku F1 --name intc-color-box-demo1
```

## Deploy to IBM Cloud / Cloud Foundry
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