#!/bin/bash
# shellcheck disable=SC2086,SC2034

CARDANO_CLI='docker run -it --rm --entrypoint /bin/cardano-cli -v /home/groot/cardano-node:/cardano -e CARDANO_NODE_SOCKET_PATH=/cardano/db/socket inputoutput/cardano-node:1.27.0'
USERNAME=$(whoami)
CNODE_PORT=6000 # must match your relay node port as set in the startup command
CNODE_HOSTNAME="rly1.cardano.mylo.farm"  # optional. must resolve to the IP you are requesting from
CNODE_BIN="/usr/local/bin"
CNODE_HOME=${NODE_HOME}
CNODE_LOG_DIR="${CNODE_HOME}/logs"
GENESIS_JSON="${CNODE_HOME}/${NODE_CONFIG}-shelley-genesis.json"
NETWORKID="$(jq -r .networkId $GENESIS_JSON)"
CNODE_VALENCY=1   # optional for multi-IP hostnames
NWMAGIC="$(jq -r .networkMagic < $GENESIS_JSON)"
[[ "${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic ${NWMAGIC}"
[[ "${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic ${NWMAGIC}"
 
export PATH="${CNODE_BIN}:${PATH}"
export CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/db/socket"

query_tip=$(${CARDANO_CLI} query tip ${NETWORK_IDENTIFIER})
blockNo=$( jq -r '.block' <<< "${query_tip}" )

# Note:
# if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
# IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
if [ "${CNODE_HOSTNAME}" != "CHANGE ME" ]; then
  T_HOSTNAME="&hostname=${CNODE_HOSTNAME}"
else
  T_HOSTNAME=''
fi
#echo "Username: ${USERNAME}"
#echo "Node Home: ${CNODE_HOME}"
#echo "Log Dir: ${CNODE_LOG_DIR}"
#echo "GENESIS_JSON: ${GENESIS_JSON}"
#echo "NETWORKID: ${NETWORKID}"
#echo "NWMAGIC: ${NWMAGIC}"
#echo "HASH_IDENTIFIER: ${HASH_IDENTIFIER}"
#echo "NETWORK_IDENTIFIER: ${NETWORK_IDENTIFIER}"
#echo "PATH: ${PATH}"
#echo "CARDANO_NODE_SOCKET_PATH: ${CARDANO_NODE_SOCKET_PATH}"
#echo "blockNo: ${blockNo}"
#echo "T_HOSTNAME: ${T_HOSTNAME}"

if [ ! -d ${CNODE_LOG_DIR} ]; then
  mkdir -p ${CNODE_LOG_DIR};
fi
 
curl -s "https://api.clio.one/htopology/v1/?port=${CNODE_PORT}&blockNo=${blockNo}&valency=${CNODE_VALENCY}&magic=${NWMAGIC}${T_HOSTNAME}" | tee -a $CNODE_LOG_DIR/topologyUpdater_lastresult.json

