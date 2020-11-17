# Getting Started
[Main](README.md)
# Pre-requisite
1. Install Python. In Windows, choose option install for all users.

## Deploy to a Window Server with Python Installed
1. zip the project folder including the virtual environment (**env** folder in this case)
2. Copy th zip file to the Windows server
3. Unzip the file to the deployment folder
4. edit color-box\env\Scripts\activate.bat, update **VIRTUAL_ENV** to the current project folder. 
E.g.
``` shell
set VIRTUAL_ENV=C:\Apps\color-box2\env
```
5. edit color-box\env\pyvenv.cfg, verify/update **home** to the Python installation folder
``` shell
home = C:\Program Files\Python39
```

## Test & Run
``` shell
cd color-box
env\Scripts\activate.bat
set FLASK_APP=color_boxes.py
python -m flask run --port 5001
```

