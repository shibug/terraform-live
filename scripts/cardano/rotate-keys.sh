#----------------------------------------------------------------------------------
# BLOCK PRODUCER NODE
#----------------------------------------------------------------------------------
dke cardano-bp bash
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node.socket
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
cd /Users/shibug/Library/CloudStorage/Dropbox/keys/cardano/mainnet
cp op.cert hot.skey kes.vkey backup/
cat node.counter
#----------------------------------------------------------------------------------
# AIR-GAPPED NODE
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.35.4 node issue-op-cert --kes-verification-key-file /keys/kes.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter --kes-period 484 --out-file /keys/op.cert
#----------------------------------------------------------------------------------
# OR
#----------------------------------------------------------------------------------
# AIR-GAPPED NODE
scp node.counter node.skey bp.cardano.mylo.farm:/data/cardano/priv/
#BP node Change the kes-period value
cardano-cli node issue-op-cert --kes-verification-key-file kes.vkey --cold-signing-key-file node.skey --operational-certificate-issue-counter node.counter --kes-period 830 --out-file op.cert
#BEFORE DELETING, VERIFY IF THE NODE COUNTER IS INCREMENTED
rm -fr node.counter node.skey
#----------------------------------------------------------------------------------
exit
docker restart cardano-bp

# AIR-GAPPED NODE
scp bp.cardano.mylo.farm:/data/cardano/priv/{kes.vkey,hot.skey,op.cert} .
