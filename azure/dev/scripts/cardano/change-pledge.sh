cd $NODE_HOME/priv
dke cardano-bp bash
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
cd /opt/cardano/cnode/priv/

cardano-cli query protocol-parameters --mainnet --out-file params.json

cardano-cli stake-pool metadata-hash --pool-metadata-file poolMetaData.json > poolMetaDataHash.txt
