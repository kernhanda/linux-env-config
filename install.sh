#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null
ln -s $SCRIPTPATH/vimconf/.vimrc ~/.vimrc
ln -s $SCRIPTPATH/.vimrc.bundles ~/.vimrc.bundles
ln -s $SCRIPTPATH/.vimrc.last ~/.vimrc.last

