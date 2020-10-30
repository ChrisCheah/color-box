
#Docker Essentials for Python Developers
https://intel.udemy.com/course/docker-essentials-for-python-developers/learn/lecture/17259344#notes

# color box
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