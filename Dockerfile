# Use Python Official Image as Base
FROM python:3.9

# Create a working directory
WORKDIR /app

# Copy all files from Build Context (folder) to Working Directory
COPY . .

# Install required Libraries & Modules
RUN pip install -r requirements.txt

# Start-up Command
CMD ["gunicorn", "--workers=1", "--bind=0.0.0.0:5011", "wsgi:app"]