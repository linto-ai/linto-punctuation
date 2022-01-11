FROM python:3.8
LABEL maintainer="stanfous@linagora.com, rbaraglia@linagora.com"
ENV PYTHONUNBUFFERED TRUE

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    g++ \
    openjdk-11-jre-headless \
    curl \
    wget

# Rust compiler for tokenizers
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

# Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Supervisor
COPY celery_app /usr/src/app/celery_app
COPY http_server /usr/src/app/http_server
COPY document /usr/src/app/document
COPY punctuation /usr/src/app/punctuation
RUN mkdir /usr/src/app/model-store
RUN mkdir -p /usr/src/app/tmp
COPY config.properties /usr/src/app/config.properties

COPY docker-entrypoint.sh wait-for-it.sh healthcheck.sh ./

ENV PYTHONPATH="${PYTHONPATH}:/usr/src/app/punctuation"
HEALTHCHECK CMD ./healthcheck.sh

ENV TEMP=/usr/src/app/tmp
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["serve"]
