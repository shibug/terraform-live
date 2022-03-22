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
cat node.counter
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.34.1 node issue-op-cert --kes-verification-key-file /keys/kes.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter --kes-period 428 --out-file /keys/op.cert

#----------------------------------------------------------------------------------
# OPTIONAL - If Docker doesn't work on mac M1, then run on BLOCK PRODUCER NODE
#----------------------------------------------------------------------------------
#Air gapped machine
scp node.counter node.skey bp.cardano.mylo.farm:/data/cardano/priv/

#BP node
cardano-cli node issue-op-cert --kes-verification-key-file kes.vkey --cold-signing-key-file node.skey --operational-certificate-issue-counter node.counter --kes-period 428 --out-file op.cert
rm -fr node.counter node.skey
exit
docker stop cardano-bp
docker start cardano-bp

#Air gapped machine
scp bp.cardano.mylo.farm:/data/cardano/priv/op.cert .
