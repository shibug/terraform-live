#----------------------------------------------------------------------------------
# BLOCK PRODUCER NODE
#----------------------------------------------------------------------------------
dke cardano-bp bash
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
export NODE_HOME=/opt/cardano/cnode
cd ${NODE_HOME}/priv

slotNo=$(cardano-cli query tip --mainnet | jq -r '.slot')
slotsPerKESPeriod=$(cat ${NODE_HOME}/files/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
startKesPeriod=${kesPeriod}
echo startKesPeriod: ${startKesPeriod}

cardano-cli node key-gen-KES --verification-key-file kes.vkey --signing-key-file hot.skey

#----------------------------------------------------------------------------------
# AIR-GAPPED NODE
#----------------------------------------------------------------------------------
cd /Users/shibug/Dropbox/keys/cardano/mainnet
cp op.cert hot.skey kes.vkey backup/
scp bp.cardano.mylo.farm:/data/cardano/priv/kes.vkey .
scp bp.cardano.mylo.farm:/data/cardano/priv/hot.skey .
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0-a node issue-op-cert --kes-verification-key-file /keys/kes.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter --kes-period 373 --out-file /keys/op.cert