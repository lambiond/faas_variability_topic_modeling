#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov 18 15:06:52 2021

@author: Danielle Lambion
@author: Bob Schmitz
"""
# We need to keep these ones
import pandas as pd
import gensim
#from gensim import corpora, models
#from gensim import models
#from gensim.utils import simple_preprocess
#from gensim.parsing.preprocessing import STOPWORDS
from nltk.stem import WordNetLemmatizer, SnowballStemmer
#from nltk.stem.porter import *
#import numpy as np
#np.random.seed(2018)
import nltk
# this will be imported in the docker image
#nltk.download('wordnet', download_dir='/tmp')
from pickle import dump, load

# Local modules
from s3

# create a dictionary that points to the functions to aid in Lambda execution
run = {"lambda_function_1": lambda_function_1(),
       "lambda_function_2": lambda_function_2(),
       "lambda_function_3": lambda_function_3()}


def lambda_function_1(training_data='/tmp/news_train.csv',
                      bucket_name='tcss562-term-project-group3'):
    # =============================================================================
    #     LOAD news_train.csv FROM S3 BUCKET
    #     We will use the last 80% of the dataset for model training
    # =============================================================================
    s3.s3_download(training_data, bucket_name) 
    df = pd.read_csv(training_data, error_bad_lines=False,
                     usecols=['publish_date', 'headline_text'])
    df['processed_text'] = df['headline_text'].apply(lambda x: process_data(x))
    dictionary = create_dict(df['processed_text'])
    corpus_tfidf = create_tfidf_model(df['processed_text'], dictionary)
    # =============================================================================
    #     SAVE corpus_tfidf AND dictionary TO S3 BUCKET
    # =============================================================================
    s3.s3_upload_object(pickle.dump(corpus_tfidf), bucket_name, 'corpus_tfidf.p')
    s3.s3_upload_object(pickle.dump(dictionary), bucket_name, 'dictionary.p')


def lambda_function_2(corpus_tfidf='/tmp/corpus_tfidf.p',
                      dictionary='/tmp/dictionary.p',
                      bucket_name='tcss562-term-project-group3'):
    # =============================================================================
    #     LOAD corpus_tfidf AND dictionary FROM S3 BUCKET
    # =============================================================================
    s3.s3_download(corpus_tfidf, corpus_tfidf)
    s3.s3_download(dictionary, corpus_tfidf)
    lda_model = gensim.models.LdaMulticore(corpus_tfidf, num_topics=5,
                                           id2word=dictionary, passes=2,
                                           workers=2)
    # =============================================================================
    #     SAVE lda_model TO S3 BUCKET
    # =============================================================================
    model_file = '/tmp/lda.model'
    lda_model.save(model_file)
    s3.s3_upload_file(model_file, bucket_name)


def lambda_function_3(test_data='/tmp/news_test.csv',
                      model_file='/tmp/lda.model',
                      dictionary_file='/tmp/dictionary.p',
                      bucket_name='tcss562-term-project-group3'):
    # =============================================================================
    #     LOAD lda_model AND dictionary AND news_test.csv FROM S3 BUCKET
    #     We will use the last 20% of the dataset to query the model
    # =============================================================================
    s3.s3_download(test_data, bucket_name) 
    s3.s3_download(dictionary_file, bucket_name) 
    s3.s3_download(model_file, bucket_name) 
    dictionary = pickle.load(dictionary_file)
    lda_model = gensim.models.LdaMulticore.load(model_file)
    df_query = pd.read_csv(test_data, error_bad_lines=False,
                           usecols=['publish_date', 'headline_text'])
    df_query['processed_text'] = df_query['headline_text'].apply(lambda x: process_data(x))
    query_tfidf = create_tfidf_model(df_query['processed_text'], dictionary)
    df_query = get_topic(df_query, lda_model, query_tfidf)
    #print(df_query['processed_text'])
    #print(df_query['headline_text'])
    #print(df_query['topic_number'])
    #print(df_query['score'])
    #print(df_query['topic'])
    # =============================================================================
    #     SAVE df_query AS A CSV TO S3 BUCKET
    #    (or return it to wherever user might want it)
    # =============================================================================
    results_file = '/tmp/results.csv'
    df_query.to_csv(results_file)
    s3.s3_upload_file("/tmp/results.csv")


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
            #print("\nScore: {}\t \nTopic: {}".format(score, model.print_topic(index, 10)))
            topics_df = topics_df.append(pd.Series([index,score,model.print_topic(index, 10)]),
                                         ignore_index=True)
    topics_df.columns = ['topic_number', 'score', 'topic']
    return df.join(topics_df)
