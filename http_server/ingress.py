#!/usr/bin/env python3

import os
from time import time
import logging
import json
import requests

from flask import Flask, request, abort, Response, json

from serving import GunicornServing
from confparser import createParser
from swagger import setupSwaggerUI
from punctuation import logger

app = Flask("__stt-standalone-worker__")

@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    return json.dumps({"healthcheck": "OK"}), 200

@app.route("/oas_docs", methods=['GET'])
def oas_docs():
    return "Not Implemented", 501

@app.route('/punctuation', methods=['POST'])
def transcribe():
    try:
        logger.info('Punctuation request received')
        return_json = False
        if request.headers.get('accept').lower() == 'application/json':
            return_json = True
        elif not request.headers.get('accept').lower() == 'text/plain':
            raise ValueError('Not accepted header')
            
        sentences = request.json.get("sentences", [])
        

        # Fetch model name
        try:
            result = requests.get("http://localhost:8081/models", 
                                headers={"accept": "application/json",},)
            models = json.loads(result.text)
            model_name = models["models"][0]["modelName"]
        except:
            raise Exception("Failed to fetch model name")

        punctuated_sentences = []
        for i, sentence in enumerate(sentences):
            result = requests.post("http://localhost:8080/predictions/{}".format(model_name),
                                headers={'content-type': 'application/octet-stream'},
                                data=sentence.strip().encode('utf-8'))
            if result.status_code == 200:
                punctuated_sentence = result.text
                # First letter in capital
                punctuated_sentence = punctuated_sentence[0].upper() + punctuated_sentence[1:]
                punctuated_sentences.append(punctuated_sentence)
            else:
                raise Exception(result.text)
        if return_json:
            return {"punctuated_sentences": punctuated_sentences}, 200
        else:
            return ". ".join(punctuated_sentences)
        return response, 200

    except ValueError as error:
        return str(error), 400
    except Exception as e:
        logger.error(e)
        return 'Server Error: {}'.format(str(e)), 500

# Rejected request handlers
@app.errorhandler(405)
def method_not_allowed(error):
    return 'The method is not allowed for the requested URL', 405

@app.errorhandler(404)
def page_not_found(error):
    return 'The requested URL was not found', 404

@app.errorhandler(500)
def server_error(error):
    logger.error(error)
    return 'Server Error', 500

if __name__ == '__main__':
    logger.info("Startup...")

    parser = createParser()
    args = parser.parse_args()
    logger.setLevel(logging.DEBUG if args.debug else logging.INFO)
    try:
        # Setup SwaggerUI
        if args.swagger_path is not None:
            setupSwaggerUI(app, args)
            logger.debug("Swagger UI set.")
    except Exception as e:
        logger.warning("Could not setup swagger: {}".format(str(e)))
    
    serving = GunicornServing(app, {'bind': '{}:{}'.format("0.0.0.0", args.service_port),
                                    'workers': args.workers,})
    logger.info(args)
    try:
        serving.run()
    except KeyboardInterrupt:
        logger.info("Process interrupted by user")
    except Exception as e:
        logger.error(str(e))
        logger.critical("Service is shut down (Error)")
        exit(e)
