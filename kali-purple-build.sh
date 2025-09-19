#!/bin/bash

scriptstarttime=$(date)

#
#############################################################################################################################################################################
#
#
#                         NOTE: for some stupid reason curl is not included in the base Debian install and will need to be installed first
#                                                 the command below has been modified to install curl also
#
#                                                     Use the curl command below to start the script
# 
#      command -v curl || sudo apt install curl && bash <(curl --silent https://raw.githubusercontent.com/robertstrom/kali-purple/refs/heads/main/kali-purple-build.sh)
#
#
#############################################################################################################################################################################

# Setting hostname
read -p "What is the hostname of this machine? " sethostname
sudo hostnamectl set-hostname $sethostname
# Fixing the hostname in the /etc/hostname file - uses the variable set above when setting the hostname
getprevhostname=$(grep 127.0.1.1 /etc/hosts | awk '{ print $2 }')
sudo  sed -i "s/$getprevhostname/$sethostname/" /etc/hosts

# Fix /etc/apt/source.list to comment out the cdrom as a source 
sudo sed -i '/^deb cdrom/ s/./# &/' /etc/apt/sources.list

touch ~/.screenrc
echo "# Enable mouse scrolling and scroll bar history scrolling" > ~/.screenrc
echo "termcapinfo xterm* ti@:te@" >> ~/.screenrc

# Create directory for sshfs mount for QNAP NAS
mkdir -p ~/QNAPMyDocs

mkdir -p /home/rstrom/.local/bin/

# Create a directory for mounting remote SMB shares
mkdir ~/SMBmount

# Create a working directory for temp type actions
mkdir ~/working


## Create a directory for copying down prebuilt Docker Images from NAS
mkdir ~/Docker-Images

# Setup fuse group and add user to fuse group for sshfs use
sudo groupadd fuse
sudo usermod -a -G fuse rstrom

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -yq

arch=$(uname -m)


case "$arch" in
  x86_64|amd64)
    sudo DEBIAN_FRONTEND=noninteractive apt install -yq shellcheck libimage-exiftool-perl pv terminator xclip dolphin krusader kdiff3 kompare xxdiff \
    krename ksnip flameshot html2text csvkit remmina sipcalc xsltproc rinetd httptunnel tesseract-ocr ncdu grepcidr speedtest-cli cifs-utils nfs-common \
    sshuttle mpack filezilla lolcat ripgrep bat dcfldd redis-tools jq keepassxc okular exfat-fuse exfatprogs xsel pandoc poppler-utils net-tools forensics-extra \
    ffmpeg fonts-liberation zbar-tools rlwrap lolcat 7zip pip virtualenv python3-virtualenv pipx tcpdump tmux fd-find tldr trash-cli bind9-dnstools \
    golang sublist3r tcpspy mono-complete zsh qemu-system-x86 libvirt-daemon-system virtinst virt-manager virt-viewer ovmf swtpm locate \
    qemu-utils guestfs-tools libosinfo-bin tuned fonts-powerline autojump htop glances btop vlc stacer audacity obs-studio handbrake handbrake-cli \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin torbrowser-launcher apt-transport-https mc gnupg2 gnupg yamllint
    ;;
  i?86)
    echo "Architecture: x86 (32-bit)"
    ;;
  arm*)
    echo "Architecture: ARM"
    ;;
  aarch64)
    echo "Architecture: AArch64 (64-bit ARM)"
    mkdir ~/Downloads
    sudo DEBIAN_FRONTEND=noninteractive apt install -yq shellcheck libimage-exiftool-perl pv terminator copyq xclip dolphin krusader kdiff3 krename kompare xxdiff krename kde-spectacle \
    flameshot html2text csvkit remmina kali-wallpapers-all hollywood-activate kali-screensaver gridsite-clients sipcalc \
    xsltproc rinetd httptunnel kerberoast tesseract-ocr ncdu grepcidr speedtest-cli sshuttle mpack filezilla lolcat \
    ripgrep bat dcfldd redis-tools feroxbuster name-that-hash jq keepassxc okular exfat-fuse exfatprogs kate xsel pandoc poppler-utils ffmpeg \
    zbar-tools gnupg2 dc3dd rlwrap partitionmanager kali-undercover fastfetch hyfetch lolcat 7zip-standalone eza \
    obsidian breeze-icon-theme trufflehog python3-trufflehogregexes coercer golang-go ligolo-ng sublist3r tcpspy xrdp libraspberrypi-bin
    ;;
  ppc64le)
    echo "Architecture: PowerPC 64-bit Little Endian"
    ;;
  *)
    echo "Architecture: Unknown ($arch)"
    ;;
esac


# Enable the docker service
sudo systemctl enable docker --now

## Enable the xrdp service
## sudo systemctl enable xrdp --now
## See this for enabling XRDP on a system running KDE Plasma using Wayland
## XRDP Server on KDE Plasma
## https://notes.benheater.com/books/linux-administration/page/xrdp-server-on-kde-plasma

# Add the currenbt user to the docker group so that you don't need to use sudo to run docker commands
sudo usermod -aG docker $USER

# Ensure that the users in the docker group have the permissions to execute docker run commands
sudo chmod 666 /var/run/docker.sock

# Install docker compose

## One way of getting the current version information from GitHub
## curl -Ls https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[].browser_download_url" | grep -v '\.json\|\.sha256'

## An alternate way of getting the current version information from GitHub
## curl -Ls https://api.github.com/repos/docker/compose/releases/latest | grep browser_download | egrep linux-aarch64\"$ | awk -F"\""  '{ print $4 }'

dockercomposelatestamd64=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[].browser_download_url" | grep docker-compose-linux-x86_64$)
dockercomposelatestaarch64=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[].browser_download_url" | grep docker-compose-linux-aarch64$)
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins

case "$arch" in
  x86_64|amd64)
    echo "Architecture: x86-64 (64-bit)"
    wget $dockercomposelatestamd64 -O $DOCKER_CONFIG/cli-plugins/docker-compose
    ;;
  i?86)
    echo "Architecture: x86 (32-bit)"
    ;;
  arm*)
    echo "Architecture: ARM"
    ;;
  aarch64)
    echo "Architecture: AArch64 (64-bit ARM)"
    ## wget $dockercomposelatestaarch64 -O $DOCKER_CONFIG/cli-plugins/docker-compose
    ;;
  ppc64le)
    echo "Architecture: PowerPC 64-bit Little Endian"
    ;;
  *)
    echo "Architecture: Unknown ($arch)"
    ;;
esac

chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# Install Visual Studio Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
rm -f packages.microsoft.gpg

sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update
sudo apt install -y code

# Install python virtual environments venv
pip install virtualenv

## 2024-11-09 - Added the install of 1password
pushd ~/Downloads

case "$arch" in
  x86_64|amd64)
    echo "Architecture: x86-64 (64-bit)"
    wget https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb
    sudo dpkg -i 1password-latest.deb
    rm 1password-latest.deb
    ;;
  i?86)
    echo "Architecture: x86 (32-bit)"
    ;;
  arm*)
    echo "Architecture: ARM"
    ;;
  aarch64)
    ## https://support.1password.com/install-linux/#arm-or-other-distributions-targz
    echo "Architecture: AArch64 (64-bit ARM)"
    curl -sSO https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz
    sudo tar -xf 1password-latest.tar.gz
    sudo mkdir -p /opt/1Password
    sudo mv 1password-*/* /opt/1Password
    sudo /opt/1Password/after-install.sh
    rm -rf 1password*
    ;;
  ppc64le)
    echo "Architecture: PowerPC 64-bit Little Endian"
    ;;
  *)
    echo "Architecture: Unknown ($arch)"
    ;;
esac
popd

# Download and Install CopyQ
copyqdownload=$(curl -s https://api.github.com/repos/hluk/CopyQ/releases/latest | jq -r ".assets[].browser_download_url" | grep Debian_12)
wget $copyqdownload -O ~/Downloads/copyq-amd64.deb
sudo dpkg -i ~/Downloads/copyq-amd64.deb
rm -rf ~/Downloads/copyq-amd64.deb

# Download the com.github.hluk.copyq.desktop file from GitHub and copy it to the ~/.config/autostart/com.github.hluk.copyq.desktop file so that CopyQ will autostart on login
mkdir -p ~/.config/autostart/
wget https://raw.githubusercontent.com/robertstrom/debian-kde-build/refs/heads/main/com.github.hluk.copyq.desktop -O ~/.config/autostart/com.github.hluk.copyq.desktop
chmod 600 ~/.config/autostart/com.github.hluk.copyq.desktop

# Install glow terminal markdown renderer
# https://github.com/charmbracelet/glow?tab=readme-ov-file
go install github.com/charmbracelet/glow@latest

# Install Obsidian

obsidianlatest=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r ".assets[].browser_download_url" | grep deb)
wget $obsidianlatest -O ~/Downloads/obsidian-latest.deb
sudo dpkg -i ~/Downloads/obsidian-latest.deb
rm -rf ~/Downloads/obsidian-latest.deb

# pipx ensurepath
pipx ensurepath --prepend

sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

## Updog web server
## https://github.com/sc0tfree/updog
pipx install updog

# Install Python HTTP Upload server
# https://pypi.org/project/uploadserver/
pipx install uploadserver

# Install knosave
# https://github.com/Prayag2/konsave
pipx install konsave

# Install wwwtree
sudo git clone https://github.com/t3l3machus/wwwtree /opt/wwwtree
pushd /opt/wwwtree
sudo pip3 install -r requirements.txt
sudo chmod +x wwwtree.py
popd
pushd /usr/bin
sudo ln -s /opt/wwwtree/wwwtree.py wwwtree
popd


####################################################################################################################
#
#                                                   Install ohmyzsh
#
#         You will need to the exit after ohmyzsh is installed and enters the zsh prompt to complete the script

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#
#
#####################################################################################################################

# Change zsh theme to agnoster
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc
### Command to test differnet way to modify the ohmyzsh plugins
## sed -i 's/plugins=(git)/plugins=(git\nautojump\ncolored-man-pages\ncolorize\ncopyfile\ncopypath\nfzf\neza)/'
sed -i 's/plugins=(git)/plugins=(git colored-man-pages colorize copyfile copypath fzf eza)/' ~/.zshrc

# Added for ohmyzsh fzf plugin
echo "export FZF_BASE=~/fzf" >> ~/.zshrc

# Install fzf via github
cd ~
git clone --depth 1 https://github.com/junegunn/fzf.git
pushd ~/fzf
./install --all
popd

# Clone the tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Nerd Fonts 

mkdir -p ~/.local/share/fonts

# Terminess Nerd Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Terminus.zip
# Nerd Font Symbols
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.zip
# Pro Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/ProFont.zip
# M+ Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/MPlus.zip
# Open Dyslexic Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/OpenDyslexic.zip
# Monoid Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Monoid.zip
# Meslo Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip
# JetBrains Mono Font
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip

pushd ~/.local/share/fonts
unzip Terminus.zip
rm Terminus.zip
unzip NerdFontsSymbolsOnly.zip
rm NerdFontsSymbolsOnly.zip
unzip ProFont.zip
rm ProFont.zip
unzip MPlus.zip
rm MPlus.zip
unzip OpenDyslexic.zip
rm OpenDyslexic.zip
unzip Monoid.zip
rm Monoid.zip
unzip Meslo.zip
rm Meslo.zip
unzip JetBrainsMono.zip
rm JetBrainsMono.zip 
fc-cache -fv
popd  

# Creating a link to the fdfind binary so that it can be launched using the command fd
ln -s $(which fdfind) ~/.local/bin/fd

# Added for launching the glow (and possibly other go applications) without having to specify the full path
# Also added the pipx ensure path since the install adds it to the bash profile, not the zshrc profile file since zsh is not active yet
echo "export PATH="$PATH:/home/rstrom/go/bin/:/home/rstrom/.local/bin"" >> .zshrc

# pipx ensurepath
# pipx ensurepath
## sudo pipx ensurepath --global # optional to allow pipx actions with --global argument

## bash <(curl --silent https://raw.githubusercontent.com/robertstrom/debian-kde-build/refs/heads/main/install_zsh.sh) && chmod a+x ~/.zshrc


# eml_analyzer - https://github.com/wahlflo/eml_analyzer
pipx install eml-analyzer

# Creating a link to the fdfind binary so that it can be launched using the command fd
ln -s $(which fdfind) ~/.local/bin/fd

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env" 

# Install cargo update
cargo install cargo-update

# Install macchina (fastfetch alternative)
cargo install macchina

# Install broot directory navigation tool
# https://dystroy.org/broot/
cargo install --locked --features clipboard broot

# Install zoxide - cd replacement
# https://github.com/ajeetdsouza/zoxide
cargo install zoxide

scriptendtime=$(date)
echo " "
echo "The script started at $scriptstarttime"
echo " "
echo "The script completed at $scriptendtime"
echo " "
echo "The installation and configuration of this new Debian build has completed"
echo " "
echo "There are still steps needed to finish the setup of KVM"
echo " "
echo "See the documentation on this web page - How Do I Properly Install KVM on Linux - https://sysguides.com/install-kvm-on-linux"
echo " "
echo " "

