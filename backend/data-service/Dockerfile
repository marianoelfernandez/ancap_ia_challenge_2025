FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV POETRY_VERSION=1.7.1

RUN apt-get update && apt-get install -y curl build-essential && \
    curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry && \
    apt-get clean


WORKDIR /app


COPY pyproject.toml poetry.lock* /app/


RUN poetry config virtualenvs.create false && poetry install --no-root


COPY . /app


EXPOSE 8001


CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
