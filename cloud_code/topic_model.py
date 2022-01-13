#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov 18 15:06:52 2021

@author: Danielle Lambion
@author: Bob Schmitz
"""

import platform
import pandas as pd
import pickle
import gensim
from gensim import models
from gensim.test.utils import datapath
from gensim.parsing.preprocessing import STOPWORDS
import nltk
from nltk.stem import WordNetLemmatizer, SnowballStemmer
import os
# this will be included in the docker image
#nltk.download('wordnet', download_dir='/tmp')

# Local modules
import s3

# Determine CPU arch for S3 buckets
arch=platform.machine().replace('_', '-')
region = os.environ.get('AWS_REGION', 'us-east-2')

# Model files
model_files=['/tmp/lda.model',
             '/tmp/lda.model.expElogbeta.npy',
             '/tmp/lda.model.id2word',
             '/tmp/lda.model.state']
cleanup_files=['lda.model',
               'lda.model.expElogbeta.npy',
               'lda.model.id2word',
               'lda.model.state',
               'dictionary.p',
               'corpus_tfidf.p'

def lambda_function_1(training_data='/tmp/news_train.csv',
                      bucket_name_in=f'topic-modeling-{region}',
                      bucket_name_out=f'topic-modeling-{region}-{arch}'):
    # =============================================================================
    #     LOAD news_train.csv FROM S3 BUCKET
    #     We will use the last 80% of the dataset for model training
    # =============================================================================
    if not os.path.exists(training_data):
        s3.s3_download(training_data, bucket_name_in)
    df = pd.read_csv(training_data, on_bad_lines='skip',
                     usecols=['publish_date', 'headline_text'])
    df['processed_text'] = df['headline_text'].apply(lambda x: process_data(x))
    dictionary = create_dict(df['processed_text'])
    corpus_tfidf = create_tfidf_model(df['processed_text'], dictionary)
    # =============================================================================
    #     SAVE corpus_tfidf AND dictionary TO S3 BUCKET
    # =============================================================================
    pickle.dump(dictionary, open('/tmp/dictionary.p', 'wb'))
    s3.s3_upload_file('/tmp/dictionary.p', bucket_name_out)
    pickle.dump(corpus_tfidf, open('/tmp/corpus_tfidf.p', 'wb'))
    s3.s3_upload_file('/tmp/corpus_tfidf.p', bucket_name_out)


def lambda_function_2(corpus_tfidf='/tmp/corpus_tfidf.p',
                      dictionary='/tmp/dictionary.p',
                      bucket_name_in=f'topic-modeling-{region}-{arch}',
                      bucket_name_out=f'topic-modeling-{region}-{arch}'):
    # =============================================================================
    #     LOAD corpus_tfidf AND dictionary FROM S3 BUCKET
    # =============================================================================
    if not os.path.exists(corpus_tfidf):
        s3.s3_download(corpus_tfidf, bucket_name_in)
    if not os.path.exists(dictionary):
        s3.s3_download(dictionary, bucket_name_in)
    corpus_tfidf = pickle.load(open(corpus_tfidf, 'rb'))
    dictionary = pickle.load(open(dictionary, 'rb'))
    # DOESN'T WORK IN LAMBDA
#    lda_model = gensim.models.LdaMulticore(corpus_tfidf, num_topics=5,
#                                           id2word=dictionary, passes=2,
#                                           workers=2)
    lda_model = models.LdaModel(corpus_tfidf, num_topics=5, id2word=dictionary)

    # =============================================================================
    #     SAVE lda_model TO S3 BUCKET
    # =============================================================================
    lda_model.save(model_files[0])
    for mfile in model_files:
        s3.s3_upload_file(mfile, bucket_name_out)


def lambda_function_3(test_data='/tmp/news_test_smaller.csv',
                      dictionary='/tmp/dictionary.p',
                      bucket_name_in=[f'topic-modeling-{region}',
                                      f'topic-modeling-{region}-{arch}'],
                      bucket_name_out=f'topic-modeling-{region}-{arch}'):
    # =============================================================================
    #     LOAD lda_model AND dictionary AND news_test.csv FROM S3 BUCKET
    #     We will use the last 20% of the dataset to query the model
    # =============================================================================
    if not os.path.exists(test_data):
        s3.s3_download(test_data, bucket_name_in[0])
    if not os.path.exists(dictionary):
        s3.s3_download(dictionary, bucket_name_in[1])
    for mfile in model_files:
        if not os.path.exists(mfile):
            s3.s3_download(mfile, bucket_name_in[1])
    dictionary = pickle.load(open(dictionary, 'rb'))
    lda_model = models.LdaModel.load(model_files[0])
    df_query = pd.read_csv(test_data, on_bad_lines='skip',
                           usecols=['publish_date', 'headline_text'])
    df_query['processed_text'] = df_query['headline_text'].apply(lambda x: process_data(x))
    query_tfidf = create_tfidf_model(df_query['processed_text'], dictionary)
    df_query = get_topic(df_query, lda_model, query_tfidf)
    # =============================================================================
    #     SAVE df_query AS A CSV TO S3 BUCKET
    #    (or return it to wherever user might want it)
    # =============================================================================
    results_file = '/tmp/results.csv'
    df_query.to_csv(results_file)
    # We could check the checksum and return instead of storing
    #s3.s3_upload_file(results_file, bucket_name_out)
    # Cleanup all application files in S3 bucket
    for f in cleanup_files:
        s3.s3_delete(bucket_name_in[1], f)


# =============================================================================
# Create a token word dictionary. Tokens that appear in less than 15 headlines
# are removed. Tokens appearing in more than 50% of the corpus are removed.
# =============================================================================
def create_dict(docs):
    dictionary = gensim.corpora.Dictionary(docs)
    dictionary.filter_extremes(no_below=15, no_above=0.5)
    return dictionary


# =============================================================================
# Create a TFIDF model from a bag-of-words generated by the corpus dictionary.
# =============================================================================
def create_tfidf_model(docs, dictionary):
    bow_corpus = [dictionary.doc2bow(doc) for doc in docs]
    tfidf = models.TfidfModel(bow_corpus)
    corpus_tfidf = tfidf[bow_corpus]
    return corpus_tfidf


# =============================================================================
# Tokenize the String text. Stopwords and words less than 3 characters are
# removed. Words are stemmed and lemmatized and tokens are returned in
# their root form.
# =============================================================================
def process_data(text):
    processed_text = []
    for token in gensim.utils.simple_preprocess(text):
        if token not in gensim.parsing.preprocessing.STOPWORDS and len(token) > 2:
            # lemmatizing verbs
            lemtext = WordNetLemmatizer().lemmatize(token, pos='v')
            # reduce to root form
            stemttext = SnowballStemmer("english").stem(lemtext)
            processed_text.append(stemttext)
    return processed_text


# =============================================================================
# Queries the model for the topic number, match score, and topic and appends
# this information onto the query dataframe.
# =============================================================================
def get_topic(df, model, tfidf):
    topics_df = pd.DataFrame()
    for tfidf_val in tfidf:
        for index, score in sorted(model[tfidf_val], key=lambda tup: -1*tup[1]):
            topics_df = topics_df.append(pd.Series([index,score,model.print_topic(index, 10)]),
                                         ignore_index=True)
    topics_df.columns = ['topic_number', 'score', 'topic']
    return df.join(topics_df)


# A dictionary that points to the functions to aid in Lambda execution
run = {"lambda_function_1": lambda_function_1,
       "lambda_function_2": lambda_function_2,
       "lambda_function_3": lambda_function_3}
