FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY color_boxes.py wsgi.py ./

RUN useradd -r -u 10001 appuser
USER 10001

EXPOSE 5011

CMD ["gunicorn", "--workers=1", "--bind=0.0.0.0:5011", "wsgi:app"]
