# LINTO-PUNCTUATION
LinTO-Punctuation is a LinTO service for punctuation prediction. It predicts punctuation from raw text or raw transcription.

LinTO-Punctuation can either be used as a standalone punctuation service or deployed as a micro-service.

## Table of content
* [Prerequisites](#pre-requisites)
  * [Models](#models)
* [Deploy](#deploy)
  * [HTTP](#http-api)
  * [MicroService](#micro-service)
* [Usage](#usages)
  * [HTTP API](#http-api)
    * [/healthcheck](#healthcheck)
    * [/punctuation](#punctuation)
    * [/docs](#docs)
  * [Using celery](#using-celery)

* [License](#license)
***

## Pre-requisites

### Models
The punctuation service relies on a trained recasing and punctuation prediction model.

Some models trained on [Common Crawl](http://data.statmt.org/cc-100/) are available on [recasepunc](https://github.com/benob/recasepunc) for the following the languages:
* French
  * [fr-txt.large.19000](https://github.com/benob/recasepunc/releases/download/0.3/fr-txt.large.19000)
  * [fr.22000](https://github.com/benob/recasepunc/releases/download/0.3/fr.22000)
* English
  * [en.23000](https://github.com/benob/recasepunc/releases/download/0.3/en.23000)
* Italian
  * [it.22000](https://github.com/CoffeePerry/recasepunc/releases/download/v0.1.0/it.22000)
* Chinese
  * [zh.24000](https://github.com/benob/recasepunc/releases/download/0.3/zh.24000)

<!-- We provide homebrew models on [dl.linto.ai](https://dl.linto.ai/downloads/model-distribution/punctuation_models/). -->

### Docker
The punctuation service requires docker up and running.

For GPU capabilities, it is also needed to install
[nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

### (micro-service) Service broker
The punctuation only entry point in job mode are tasks posted on a REDIS message broker using [Celery](https://github.com/celery/celery). 

## Deploy
linto-punctuation can be deployed two different ways:
* As a standalone punctuation service through an HTTP API.
* As a micro-service connected to a task queue.

**1- First step is to build the image:**

```bash
git clone https://github.com/linto-ai/linto-punctuation.git
cd linto-punctuation
docker build . -t linto-punctuation:latest
```

or 
```bash
docker pull registry.linto.ai/lintoai/linto-punctuation:latest
```

**2- Download the models**

Have the punctuation model ready at `<MODEL_PATH>`.

### HTTP

**1- Fill the .env**
```bash
cp .env_default .env
```

Fill the .env with your values.

**Parameters:**
| Variables | Description | Example |
|:-|:-|:-|
| SERVICE_NAME | The service's name | my_punctuation_service |
| CONCURRENCY | Number of worker | > 1 |

**2- Run with docker**

```bash
docker run --rm \
-v <MODEL_PATH>:/usr/src/app/model-store/model \
-p HOST_SERVING_PORT:80 \
--env-file .env \
linto-punctuation:latest
```

Also add ```--gpus all``` as an option to enable GPU capabilities.

This will run a container providing an http API binded on the host HOST_SERVING_PORT port.


### Micro-service
>LinTO-Punctuation can be deployed as a microservice. Used this way, the container spawn celery workers waiting for punctuation tasks on a dedicated task queue.
>LinTO-Punctuation in task mode requires a configured REDIS broker.

You need a message broker up and running at MY_SERVICE_BROKER. Instance are typically deployed as services in a docker swarm using the docker compose command:

**1- Fill the .env**
```bash
cp .env_default .env
```

Fill the .env with your values.

**Parameters:**
| Variables | Description | Example |
|:-|:-|:-|
| SERVICES_BROKER | Service broker uri | redis://my_redis_broker:6379 |
| BROKER_PASS | Service broker password (Leave empty if there is no password) | my_password |
| QUEUE_NAME | (Optionnal) overide the generated queue's name (See Queue name bellow) | my_queue |
| SERVICE_NAME | Service's name | punctuation-ml |
| LANGUAGE | Language code as a BCP-47 code | en-US or * or languages separated by "\|" |
| MODEL_INFO | Human readable description of the model | "Bert based model for french punctuation prediction" | 
| CONCURRENCY | Number of worker (1 worker = 1 cpu) | >1 |

> Do not use spaces or character "_" for SERVICE_NAME or language.

**2- Fill the docker-compose.yml**

`#docker-compose.yml`
```yaml
version: '3.7'

services:
  punctuation-service:
    image: linto-punctuation:latest
    volumes:
      - /my/path/to/models/punctuation.mar:/usr/src/app/model-store/model
    env_file: .env
    deploy:
      replicas: 1
    networks:
      - your-net

networks:
  your-net:
    external: true
```

**3- Run with docker compose**

```bash
docker stack deploy --resolve-image always --compose-file docker-compose.yml your_stack
```

**Queue name:**

By default the service queue name is generated using SERVICE_NAME and LANGUAGE: `punctuation_{LANGUAGE}_{SERVICE_NAME}`.

The queue name can be overided using the QUEUE_NAME env variable. 

**Service discovery:**

As a micro-service, the instance will register itself in the service registry for discovery. The service information are stored as a JSON object in redis's db0 under the id `service:{HOST_NAME}`.

The following information are registered:

```json
{
  "service_name": $SERVICE_NAME,
  "host_name": $HOST_NAME,
  "service_type": "punctuation",
  "service_language": $LANGUAGE,
  "queue_name": $QUEUE_NAME,
  "version": "1.2.0", # This repository's version
  "info": "Punctuation model for french punctuation prediction",
  "last_alive": 65478213,
  "concurrency": 1
}
```

## Usages

### HTTP API

#### /healthcheck

Returns the state of the API

Method: GET

Returns "1" if healthcheck passes.

#### /punctuation

Punctuation API

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

### Using Celery

Punctuation-Worker accepts celery tasks with the following arguments:
```text: Union[str, List[str]]```

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

## Acknowledgments
* [recasepunc](https://github.com/benob/recasepunc) Python library to train recasing and punctuation models, and to apply them (License BSD 3).