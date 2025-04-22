rm -rf $HOME/TDMODGAME

pkg update && pkg upgrade 

pkg install git

pkg install bind-tools

pkg install dnsutils

termux-setup-storage

git clone https://github.com/TDMODGAME/Checkip

cd Checkip

chmod +x checkip.sh

./checkip.sh
