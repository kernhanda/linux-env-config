#!/bin/bash

sudo apt-get install byobu
git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null
ln -s $SCRIPTPATH/vimconf/.vimrc ~/.vimrc
ln -s $SCRIPTPATH/.vimrc.bundles ~/.vimrc.bundles
ln -s $SCRIPTPATH/.vimrc.last ~/.vimrc.last
ln -s $SCRIPTPATH/.bash_profile ~/.bash_profile
ln -s $SCRIPTPATH/.bashrc ~/.bashrc
ln -s $SCRIPTPATH/.spacemacs ~/.spacemacs

