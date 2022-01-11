# LINTO-PLATFORM-PUNCTUATION
LinTO-platform-punctuation is the punctuation service within the [LinTO stack](https://github.com/linto-ai/linto-platform-stack).

The Punctuation is configured with an .mar BERT model.

LinTO-platform-puntuation can either be used as a standalone punctuation service or deployed within a micro-services infrastructure using a message broker connector.

## Pre-requisites

### Model
The punctuation service relies on a BERT model.

We provide some models on [dl.linto.ai](https://dl.linto.ai/downloads/model-distribution/punctuation_models/).

### Docker
The transcription service requires docker up and running.

### (micro-service) Service broker
The punctuation only entry point in job mode are tasks posted on a message broker. Supported message broker are RabbitMQ, Redis, Amazon SQS.

## Deploy linto-platform-stt
linto-platform-stt can be deployed two ways:
* As a standalone punctuation service through an HTTP API.
* As a micro-service connected to a message broker.

**1- First step is to build the image:**

```bash
git clone https://github.com/linto-ai/linto-platform-punctuation.git
cd linto-platform-punctuation
docker build . -t linto-platform-punctuation:latest
```

**2- Download the models**

Have the punctuation model (.mar) ready at MODEL_PATH.

### HTTP API

```bash
docker run --rm \
-v MODEL_PATH:/usr/src/app/model-store/punctuation.mar \
--env CONCURRENCY=1 \
--env LANGUAGE=fr_FR \
--env SERVICE_MODE=http \
linto-platform-punctuation:latest
```

This will run a container providing an http API binded on the host HOST_SERVING_PORT port.

**Parameters:**
| Variables | Description | Example |
|:-|:-|:-|
| MODEL_PATH | Your localy available model (.mar) | /my/path/to/models/punctuation.mar |
| LANGUAGE | Language code as a BCP-47 code  | en-US, fr_FR, ... |
| CONCURRENCY | Number of worker | 1 |

### Micro-service within LinTO-Platform stack
>LinTO-platform-punctuation can be deployed within the linto-platform-stack through the use of linto-platform-services-manager. Used this way, the container spawn celery worker waiting for punctuation task on a message broker.
>LinTO-platform-punctuation in task mode is not intended to be launch manually.
>However, if you intent to connect it to your custom message's broker here are the parameters:

You need a message broker up and running at MY_SERVICE_BROKER.

```bash
docker run --rm \
-v MODEL_PATH:/usr/src/app/model-store/punctuation.mar \
--env SERVICES_BROKER=redis://MY_BROKER:BROKER_PORT \
--env BROKER_PASS=password \
--env CONCURRENCY=1 \
--env LANGUAGE=fr_FR \
--env SERVICE_MODE=task \
linto-platform-punctuation:latest
```

**Parameters:**
| Variables | Description | Example |
|:-|:-|:-|
| MODEL_PATH | Your localy available model (.mar) | /my/path/to/models/punctuation.mar |
| SERVICES_BROKER | Service broker uri | redis://my_redis_broker:6379 |
| BROKER_PASS | Service broker password (Leave empty if there is no password) | my_password |
| LANGUAGE | Transcription language | en-US |
| CONCURRENCY | Number of worker (1 worker = 1 cpu) | [ 1 -> numberOfCPU] |

## Usages

### HTTP API

#### /healthcheck

Returns the state of the API

Method: GET

Returns "1" if healthcheck passes.

#### /punctuation

Transcription API

* Method: POST
* Response content: text/plain or application/json
* Body: A json object structured as follows:
```json
{
  "sentences": [
    "this is sentence 1", "is that a second sentence", "yet an other sentence"
  ]
}
```

Return the punctuated text as a json object structured as follows:
```json
{
  "punctuated_sentences": [
    "This is sentence 1",
    "Is that a second sentence ?",
    "Yet an other sentence"
  ]
}
```

#### /docs
The /docs route offers a OpenAPI/swagger interface. 

### Through the message broker

STT-Worker accepts requests with the following arguments:
```file_path: str, with_metadata: bool```

* <ins>text</ins>: (str or list) A sentence or a list of sentences.

#### Return format

Returns a string or a list of string depending on the input parameter.

## Test
### Curl
You can test you http API using curl:
```bash 
curl -X POST "http://YOUR_SERVICE:YOUR_PORT/punctuation" -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \"sentences\": [    \"this is sentence 1\", \"is that a second sentence\", \"yet an other sentence\"  ]}"
```

## License
This project is developped under the AGPLv3 License (see LICENSE).
