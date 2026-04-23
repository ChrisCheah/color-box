
# Getting Started (Linux)
[Main](README.md)

## Setting Up
```shell
git clone https://gitlab.devtools.intel.com/cheahchr/color-box.git
cd color-box
python -m venv env
source env/bin/activate
```

## Build & Run with gunicorn
```shell
pip install -r requirements.txt
gunicorn --bind 0.0.0.0:5011 wsgi:app
```

## Build & Run with Podman
```shell
podman build -t colorbox:0.2 .
podman run -d --name colorbox -p 5011:5011 colorbox:0.2
```

See [GettingStartedCaaS.md](GettingStartedCaaS.md) for Intel CaaS deployment instructions.