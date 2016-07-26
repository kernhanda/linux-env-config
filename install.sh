#!/bin/bash

sudo apt-get install -y byobu zsh 
git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null
ln -f -s $SCRIPTPATH/vimconf/.vimrc ~/.vimrc
ln -f -s $SCRIPTPATH/.vimrc.bundles ~/.vimrc.bundles
ln -f -s $SCRIPTPATH/.vimrc.last ~/.vimrc.last
ln -f -s $SCRIPTPATH/.bash_profile ~/.bash_profile
ln -f -s $SCRIPTPATH/.bashrc ~/.bashrc
ln -f -s $SCRIPTPATH/.spacemacs ~/.spacemacs
ln -f -s $SCRIPTPATH/.zshrc ~/.zshrc

chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

