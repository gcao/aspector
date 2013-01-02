#!/bin/sh

for f in examples/*
do
  echo
  echo === Running $f ===
  echo
  ruby $f 
  echo
  echo
done

