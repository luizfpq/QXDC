#!/usr/bin/env bash
# author:   Luiz Quirino <luizfpq@gmail.com>
# since:    v0.0.1
# version:  v0.0.1  
# created:  2021-09-11
# modified: 2021-09-11
# used inside load.sh, as a log generator

LOGDIR='/tmp/qxdc'

logger() {
    if [ -d $LOGDIR ] 
        then
            echo "Default log dir found in → "$LOGDIR 
            echo "Moving older logs to $LOGDIR-old"
            sudo rm -rf mkdir $LOGDIR-old
            sudo mv -f $LOGDIR $LOGDIR-old
            sudo mkdir $LOGDIR
            sudo chmod 777 -Rfv $LOGDIR
            echo "Ready to log..."
        else
            echo "Default log dir not found in → "$LOGDIR
            echo "Creating..."
            sudo mkdir $LOGDIR
            
            [ ! -d $LOGDIR ] && echo "Error creating dir." || sudo chmod 777 -Rfv $LOGDIR && echo "Ready to log..."
        fi

}