#!/bin/bash
for dir in "$@"
do
  i=0
  for url in `python json2urls.py $dir/index.json`
  do
    wget -t 1 --timeout=10 $url -O $dir/`printf %04d.img $i`
    i=$((i+1))
  done
done
