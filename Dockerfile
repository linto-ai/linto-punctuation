FROM python:3.9
LABEL maintainer="jlouradour@linagora.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        curl \
        libtinfo5 \
        gosu \
        wget

# Rust compiler for tokenizers
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

# Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/torch_stable.html

# Supervisor
COPY celery_app /usr/src/app/celery_app
COPY http_server /usr/src/app/http_server
COPY document /usr/src/app/document
COPY punctuation /usr/src/app/punctuation
RUN mkdir /usr/src/app/model-store
RUN mkdir -p /usr/src/app/tmp
COPY docker-entrypoint.sh wait-for-it.sh healthcheck.sh ./

ENV PYTHONPATH="${PYTHONPATH}:/usr/src/app/punctuation"
HEALTHCHECK CMD ./healthcheck.sh

ENV TEMP=/usr/src/app/tmp
ENTRYPOINT ["./docker-entrypoint.sh"]
