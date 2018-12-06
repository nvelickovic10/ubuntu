#!/bin/bash

array_contains () { 
    local arr=$1
    local seek=$2
    local in=1
    for el in ${arr} ; do
        if [[ ${el} == ${seek} ]]; then
            in=0
            break
        fi
    done
    return $in
}