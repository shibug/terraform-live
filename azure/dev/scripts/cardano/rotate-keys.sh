#----------------------------------------------------------------------------------
# BLOCK PRODUCER NODE
#----------------------------------------------------------------------------------
dke cardano-bp bash
cd ${NODE_HOME}/priv
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
export NODE_HOME=/opt/cardano/cnode

slotNo=$(cardano-cli query tip --mainnet | jq -r '.slot')
slotsPerKESPeriod=$(cat ${NODE_HOME}/files/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
startKesPeriod=${kesPeriod}
echo startKesPeriod: ${startKesPeriod}

cardano-cli node key-gen-KES --verification-key-file kes.vkey --signing-key-file hot.skey

#----------------------------------------------------------------------------------
# AIR-GAPPED NODE
#----------------------------------------------------------------------------------
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.29.0 node issue-op-cert --kes-verification-key-file /keys/kes.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter --kes-period 319 --out-file /keys/op.cert