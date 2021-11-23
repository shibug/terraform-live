#8. Start the nodes
docker run -d -h bp.cardano.mylo.farm --name cardano-bp -p 6000:6000 -p 12781:12781 -p 12798:12798 --restart on-failure:3 --security-opt="no-new-privileges=true" \
	-e NETWORK=testnet -e POOL_DIR=/opt/cardano/cnode/priv -v /home/groot/cardano/sockets:/opt/cardano/cnode/sockets -v /home/groot/cardano/priv:/opt/cardano/cnode/priv -v /home/groot/cardano/db:/opt/cardano/cnode/db \
    -v /home/groot/cardano/logs:/opt/cardano/cnode/logs -v /home/groot/cardano/config/testnet-topology.json:/opt/cardano/cnode/files/topology.json shibug/cardano-node:1.31.0

dke cardano-bp /opt/cardano/cnode/scripts/gLiveView.sh

docker run -d -h rly1.cardano.mylo.farm --name cardano-rly1 -p 6000:6000 -p 12781:12781 -p 12798:12798 --restart on-failure:3 --security-opt="no-new-privileges=true" \
	-e NETWORK=testnet -v /home/groot/cardano/sockets:/opt/cardano/cnode/sockets -v /home/groot/cardano/priv:/opt/cardano/cnode/priv -v /home/groot/cardano/db:/opt/cardano/cnode/db \
    -v /home/groot/cardano/logs:/opt/cardano/cnode/logs -v /home/groot/cardano/config/testnet-topology.json:/opt/cardano/cnode/files/topology.json shibug/cardano-node:1.31.0

dke cardano-rly1 /opt/cardano/cnode/scripts/gLiveView.sh

#9. Generate block-producer keys
cd $NODE_HOME/priv
cardano-cli node key-gen-KES --verification-key-file kes.vkey --signing-key-file kes.skey

export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
slotsPerKESPeriod=$(cat /opt/cardano/cnode/files/genesis.json | jq -r '.slotsPerKESPeriod')
echo slotsPerKESPeriod: ${slotsPerKESPeriod}
slotNo=$(cardano-cli query tip --testnet-magic $(cat /opt/cardano/cnode/files/genesis.json | jq -r .networkMagic) | jq -r '.slot')
echo slotNo: ${slotNo}
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
echo kesPeriod: ${kesPeriod}
startKesPeriod=${kesPeriod}
echo startKesPeriod: ${startKesPeriod}

#10 Setup payment and stake keys
cardano-cli query protocol-parameters --testnet-magic $(cat /opt/cardano/cnode/files/genesis.json | jq -r .networkMagic)  --out-file params.json

#11 Register your stake address
currentSlot=$(cardano-cli query tip --testnet-magic $(cat /opt/cardano/cnode/files/genesis.json | jq -r .networkMagic) | jq -r '.slot')
echo Current Slot: $currentSlot
cardano-cli query utxo --address $(cat payment.addr) --testnet-magic $(cat /opt/cardano/cnode/files/genesis.json | jq -r .networkMagic) > fullUtxo.out


#Air-gapped node
docker pull shibug/cardano-node:1.31.0
dki --entrypoint cardano-cli shibug/cardano-node:1.31.0 --version
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 node key-gen --cold-verification-key-file /keys/node.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 node issue-op-cert --kes-verification-key-file /keys/kes.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter --kes-period 233 --out-file /keys/node.cert

#10 Setup payment and stake keys
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 address key-gen --verification-key-file /keys/payment.vkey --signing-key-file /keys/payment.skey
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address key-gen --verification-key-file /keys/stake.vkey --signing-key-file /keys/stake.skey
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address build --stake-verification-key-file /keys/stake.vkey --out-file /keys/stake.addr --testnet-magic 1097911063
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 address build --payment-verification-key-file /keys/payment.vkey --stake-verification-key-file /keys/stake.vkey --out-file /keys/payment.addr --testnet-magic 1097911063
scp -P 22 payment.addr groot@bp.cardano.mylo.farm:/home/groot/cardano/priv/

#11 Register your stake address
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address registration-certificate --stake-verification-key-file /keys/stake.vkey --out-file /keys/stake.cert