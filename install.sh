#!/bin/bash

PWD=$(pwd)

function installPacakges() {
  cat files/packages.lst | tr '\n' '  ' | xargs apt-get install -y
  sudo apt-mark manual $(cat files/packages.lst)

  sudo pip install -U pip setuptools
  sudo pip install -U thefuck
  sudo pip install -U howdoi

  sudo npm install -g coffee-scrip
  sudo npm install -g azure-cli
}

function installFonts() {
  mkdir -p $HOME/.fonts/

  curl -fLo DroidSansMonoForPowerlinePlusNerdFileTypes.otf https://raw.githubusercontent.com/ryanoasis/nerd-fonts/0.6.0/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20for%20Powerline%20Nerd%20Font%20Complete.otf
  sudo chmod 664 DroidSansMonoForPowerlinePlusNerdFileTypes.otf
  mv *.otf $HOME/.fonts/
  wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
  sudo mv PowerlineSymbols.otf /usr/share/fonts/
  if ! [ -d $HOME/.fonts/ubuntu-mono-powerline-ttf ]
    git clone https://github.com/pdf/ubuntu-mono-powerline-ttf.git $HOME/.fonts/ubuntu-mono-powerline-ttf
  else
    cd $HOME/.fonts/ubuntu-mono-powerline-ttf
    git pull
    cd ${PWD}
  fi
  sudo fc-cache -vf
  sudo mv 10-powerline-symbols.conf /etc/fonts/conf.d/
}

function installDotFiles() {
  mkdir -p $HOME/.bash/

  cp files/terminator.config $HOME/.config/terminator/
  cp files/tilda $HOME/.config/tilda/config_0
  if ! [ -s  $HOME/.config/terminator/config ]; then
    ln -s $HOME/.config/terminator/terminator.config $HOME/.config/terminator/config
  fi
  cp files/git_prompt.sh $HOME/.bash/
  cp files/shell_prompt.sh $HOME/.bash/
  cp files/bashrc $HOME/.bashrc
  cp files/bash_profile $HOME/.bash_profile
  cp files/screenrc $HOME/.screenrc
  cp files/tmux.conf.local $HOME/.tmux.conf.local
  cp files/profile $HOME/.profile
  cp files/vimrc $HOME/.vimrc
  cp files/vimrc.local $HOME/.vimrc.local
  cp files/atom/* $HOME/.atom/
  cp files/git-prompt-colors.sh $HOME/.git-prompt-colors.sh
  sudo cp files/docker-enter-completion /etc/bash_completion.d/

  SHELLVARS=$(comm -3 <(compgen -v | sort) <(compgen -e | sort)|grep -v '^_')
  source config.sh
  CONF=$(comm -3 <(compgen -v | sort) <(compgen -e | sort)|grep -v '^_')
  CONF=$(comm -3 <(echo $CONF | tr ' ' '\n' | sort -u ) <(echo $SHELLVARS | tr ' ' '\n' | sort -u) | grep -v 'SHELLVARS')
  #read -p "Please enter your name (for gitconfig):" NAME
  #read -p "Please enter your email address (for gitconfig):" EMAIL

  #cp files/bash_aliases $HOME/.bash_aliases
  sedcmd=''
  for var in $(echo $CONF);do
    printf -v sc 's|${%s}|%s|;' $var "${!var//\//\\/}"
    sedcmd+="$sc"
  done
  cat files/bash_aliases | sed -e "$sedcmd" > $HOME/.bash_aliases

  # cp files/gitconfig $HOME/.gitconfig
  sedcmd=''
  for var in NAME EMAIL;do
    printf -v sc 's|${%s}|%s|;' $var "${!var//\//\\/}"
    sedcmd+="$sc"
  done
  cat files/gitconfig | sed -e "$sedcmd" > $HOME/.gitconfig

  if [ ! -d  $HOME/.bash/bash-git-prompt ]; then
    git clone https://github.com/magicmonty/bash-git-prompt.git $HOME/.bash/bash-git-prompt
  else
    cd $HOME/.bash/bash-git-prompt
    git pull
    cd ${PWD}
  fi

  if [ ! -d  $HOME/.bash/powerline-shell ]; then
    git clone https://github.com/milkbikis/powerline-shell $HOME/.bash/powerline-shell
  else
    cd $HOME/.bash/powerline-shell
    git pull
    cd ${PWD}
  fi

  if [ ! -d  $HOME/.tmux ]; then
    git clone https://github.com/gpakosz/.tmux.git $HOME/.tmux
  else
    cd $HOME/.tmux/
    git pull
    cd ${PWD}
  fi
  if [ ! -s $HOME/.tmux.conf ]; then
    ln -s $HOME/.tmux/.tmux.conf $HOME/.tmux.conf
  fi
}

function installAtomPackages() {
  # Backup package list with:
  #   apm list --installed --bare | cut -d'@' -f1 | grep -vE '^$' > atom-packages.lst
  cp files/atom/* $HOME/.atom/
  apm install --packages-file files/atom-packages.lst
}

function installVimPlugins() {
  cp files/vimrc $HOME/.vimrc
  cp files/vimrc.local $HOME/.vimrc.local
  mkdir -p $HOME/.vim/bundle/

  if [ ! -d  $HOME/.vim/bundle/Vundle.vim ]; then
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
  fi

  vim +PluginInstall +qall
  cd $HOME/.vim/bundle/YouCompleteMe
  ./install.py
}

function installAll() {
  installPacakges
  installFonts
  installDotFiles
  installVimPlugins
  installAtomPackages
}

case "$1" in
  "packages" | "pkgs")
    installPacakges
    ;;
  "dotfiles")
   installDotFiles
    ;;
  "fonts")
    installFonts
    ;;
  "vimplugins" | "vim")
    installVimPlugins
    ;;
  "atompackages" | "apkgs" | "atom")
    installAtomPackages
    ;;
  *)
    installAll
    ;;
esac
