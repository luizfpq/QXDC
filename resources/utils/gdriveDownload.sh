#!/usr/bin/env bash
# author:    Luiz Quirino
# since:     v0.0.3
# created:   2023-09-19
# modified:  2023-09-19
#adicionando ao fim da linha, seu pacote será instalado
function gdriveDownload(){
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id='$1 -O $2
}
