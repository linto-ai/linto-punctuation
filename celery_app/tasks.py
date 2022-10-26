import json
from typing import Union

import requests

from celery_app.celeryapp import celery


@celery.task(name="punctuation_task", bind=True)
def punctuation_task(self, text: Union[str, list]):
    """punctuation_task do a synchronous call to the punctuation serving API"""
    self.update_state(state="STARTED")
    # Fetch model name
    try:
        result = requests.get(
            "http://localhost:8081/models",
            headers={
                "accept": "application/json",
            },
        )
        models = json.loads(result.text)
        model_name = models["models"][0]["modelName"]
    except Exception as error:
        raise Exception("Failed to fetch model name") from error

    if isinstance(text, str):
        sentences = [text]
    else:
        sentences = text
    punctuated_sentences = []
    for i, sentence in enumerate(sentences):
        self.update_state(state="STARTED", meta={"current": i, "total": len(sentences)})

        result = requests.post(
            f"http://localhost:8080/predictions/{model_name}",
            headers={"content-type": "application/octet-stream"},
            data=sentence.strip().encode("utf-8"),
        )
        if result.status_code == 200:
            punctuated_sentence = result.text
        else:
            print("Failed to predict punctuation on sentence: >{sentence}<")
            punctuated_sentence = sentence
        punctuated_sentence = punctuated_sentence[0].upper() + punctuated_sentence[1:]
        punctuated_sentences.append(punctuated_sentence)

    return (
        punctuated_sentences[0]
        if len(punctuated_sentences) == 1
        else punctuated_sentences
    )
