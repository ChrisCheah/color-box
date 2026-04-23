
# Color Box

A simple RESTful API server built with Python 3.14 and Flask 3.x, containerized with Podman for deployment to Intel CaaS.

## Getting Started

[ [Linux](GettingStartedLinux.md) ] [ [CaaS Deployment](GettingStartedCaaS.md) ]

### Setting Up (Local Development)
```shell
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv env
# Windows
env\Scripts\activate.bat
# Linux/macOS
source env/bin/activate
```

### Build & Run Locally
```shell
pip install -r requirements.txt
gunicorn --bind 0.0.0.0:5011 wsgi:app
```

### Build & Run with Podman
```shell
podman build -t colorbox:0.2 .
podman run -d --name colorbox -p 5011:5011 colorbox:0.2
```

## Deploy to Intel CaaS
See [GettingStartedCaaS.md](GettingStartedCaaS.md) for full instructions on building, pushing, and deploying to Intel CaaS with Podman and Kubernetes.

## Available API
```
GET     '/'                                - returns greetings string
GET     '/box'                             - returns HTML list of boxes with number of balls in them
GET     '/box/<string:color>'              - return number of balls in <color> box
POST    '/box/<string:color>'              - create an empty box painted with <color>
DELETE  '/box/<string:color>'              - remove box painted with <color>
PUT     '/box/<string:color>/<int:balls>'  - update number of <balls> in box painted with <color>
```

## Tech Stack
- Python 3.14
- Flask 3.1.3
- Gunicorn 25.3.0
- Podman (OCI container via Containerfile)

## Refactor History
See [RefactorPlan.md](RefactorPlan.md) for the full refactor plan documenting the migration from Docker/Cloud Foundry to Podman/Intel CaaS.