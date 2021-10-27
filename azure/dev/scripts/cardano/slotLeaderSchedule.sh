#Scheduled Blocks Python version
gcl https://github.com/adasnakepool/ScheduledBlocks.git
cd ScheduledBlocks
sudo apt-get update
sudo apt-get -y install python3-pip libtool
pip3 --version
pip install -r requirements.txt
cp config.yaml.default config.yaml
vi config.yaml

timezone: "America/Chicago"
blockfrost_id: "KjSHiUklMl92jG170Z0fsXjvQvJBxoV8"
pool_id: "90e719ff625d4652a6f41568f9cdc0c8ddf90a7556929b4d30298e8c"
pool_ticker: "MYLO"
vrf_key: "/data/cardano/priv/vrf.skey"

#Install Libsodium
gcl https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install

python3 ScheduledBlocks.py


-----------------------
#CNCLI Version

#dki -e NETWORK=mainnet -u root -v /data/cardano/sockets:/opt/cardano/cnode/sockets --entrypoint bash --no-healthcheck shibug/cardano-node:1.30.1
dke -u root cardano-bp bash

apt-get update
apt-get -y install libpq-dev python3 build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev systemd libsystemd-dev libsodium-dev zlib1g-dev make g++ tmux git jq libncursesw5 gnupg aptitude libtool autoconf secure-delete iproute2 bc tcptraceroute dialog automake sqlite3 bsdmainutils libusb-1.0-0-dev libudev-dev

###
### On blockproducer
###
RELEASETAG=$(curl -s https://api.github.com/repos/AndrewWestberg/cncli/releases/latest | jq -r .tag_name)
VERSION=$(echo ${RELEASETAG} | cut -c 2-)
echo "Installing release ${RELEASETAG}"
curl -sLJ https://github.com/AndrewWestberg/cncli/releases/download/${RELEASETAG}/cncli-${VERSION}-x86_64-unknown-linux-gnu.tar.gz -o /tmp/cncli-${VERSION}-x86_64-unknown-linux-gnu.tar.gz
tar xzvf /tmp/cncli-${VERSION}-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin/
command -v cncli
./cncli.sh sync