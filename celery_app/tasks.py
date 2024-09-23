from typing import Union

from celery_app.celeryapp import celery

from punctuation.recasepunc import load_model, generate_predictions

MODEL = load_model()

@celery.task(name="punctuation_task", bind=True)
def punctuation_task(self, text: Union[str, list]):
    """punctuation_task do a synchronous call to the punctuation serving API"""
    self.update_state(state="STARTED")
    
    unique = isinstance(text, str)

    if unique:
        sentences = [text]
    else:
        sentences = text
    punctuated_sentences = generate_predictions(MODEL, sentences)

    return (
        punctuated_sentences[0]
        if unique
        else punctuated_sentences
    )
