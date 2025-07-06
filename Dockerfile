FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Tell Flask where to find the app
ENV FLASK_APP=main.py

CMD ["flask", "run", "--host=0.0.0.0"]
