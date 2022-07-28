#!/usr/bin/env bash
# author:   Luiz Quirino <luizfpq@gmail.com>
# since:    v0.0.1
# version:  v0.0.1  
# created:  2021-09-11
# modified: 2021-09-11
# Load and exec a .sh file with a main command with same name


load() {
    #if [ $2  ]; then
    #    echo "excesso de parametros"
    #    return 1
    #fi
    
    source ./resources/include/$1.sh
    # check if exists, then execute
    [[ $(type -t $1) == function ]] && $1
}