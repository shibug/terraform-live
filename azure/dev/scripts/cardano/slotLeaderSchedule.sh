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