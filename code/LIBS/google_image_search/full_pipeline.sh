#!/bin/bash
# query file
# output directory
python run_queries.py $1 $2
./download_imgs.sh $2/*
