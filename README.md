# Checkip
rm -rf $HOME/TDMODGAME

pkg update && pkg upgrade

pkg install git

termux-setup-storage

git clone https://github.com/TDMODGAME/Checkip/checkip.sh

cd Checkip

chmod +x checkip.sh

./checkip.sh
