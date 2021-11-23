#!/bin/bash
set -e

#CNCLI Version of leader log check

NODE_HOME=/data/cardano
SQLITE3_BIN=/usr/bin/sqlite3
CNCLI_BIN=/usr/local/bin/cncli
POOLID=90e719ff625d4652a6f41568f9cdc0c8ddf90a7556929b4d30298e8c
OPTION=${1}

if [[ ${OPTION} =~ (prev|current|next) ]]; then
    echo "Checking for assigned slots in ${OPTION} epoch..."
else
    echo "Valid parameters are prev, current or next"
    exit 1
fi

case ${OPTION} in
    prev)
        POOL_STAKE_OPT=poolStakeGo
        ACTIVE_STAKE_OPT=activeStakeGo
        LEDGER_SET_OPT=prev
    ;;
    current)
        POOL_STAKE_OPT=poolStakeSet
        ACTIVE_STAKE_OPT=activeStakeSet
        LEDGER_SET_OPT=current
    ;;
    next)
        POOL_STAKE_OPT=poolStakeMark
        ACTIVE_STAKE_OPT=activeStakeMark
        LEDGER_SET_OPT=next
    ;;
esac

if [[ -e ${SQLITE3_BIN} ]]; then
    echo "SQLite3 DB is installed"
else
    echo "SQLite3 DB is not available, installing..."
    sudo apt update
    sudo apt -y install sqlite3
fi

if [[ -e ${CNCLI_BIN} ]]; then
    echo "CNCLI is installed"
else
    echo "CNCLI is not available, installing..."
    RELEASETAG=$(curl -s https://api.github.com/repos/AndrewWestberg/cncli/releases/latest | jq -r .tag_name)
    VERSION=$(echo ${RELEASETAG} | cut -c 2-)
    echo "Installing release ${RELEASETAG}"
    curl -sLJ https://github.com/AndrewWestberg/cncli/releases/download/${RELEASETAG}/cncli-${VERSION}-x86_64-unknown-linux-gnu.tar.gz -o /tmp/cncli-${VERSION}-x86_64-unknown-linux-gnu.tar.gz
    tar xzvf /tmp/cncli-${VERSION}-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin/
    command -v cncli
fi

echo "Synchronizing Ledger logs..."
${CNCLI_BIN} sync --host 127.0.0.1 --port 6000 --no-service

SNAPSHOT=$(docker run -it --rm -e CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket -v /data/cardano/priv:/keys -v /data/cardano/sockets:/opt/cardano/cnode/sockets --entrypoint cardano-cli shibug/cardano-node:1.31.0 query stake-snapshot --stake-pool-id ${POOLID} --mainnet)
echo "SNAPSHOT: ${SNAPSHOT}"
POOL_STAKE=$(echo ${SNAPSHOT} | jq .${POOL_STAKE_OPT})
echo "POOL_STAKE: ${POOL_STAKE}"
ACTIVE_STAKE=$(echo $SNAPSHOT | jq .${ACTIVE_STAKE_OPT})
echo "ACTIVE_STAKE: ${ACTIVE_STAKE}"
MYPOOL=$(/usr/local/bin/cncli leaderlog --pool-id ${POOLID} --pool-vrf-skey ${NODE_HOME}/priv/vrf.skey --byron-genesis ${NODE_HOME}/config/mainnet-byron-genesis.json --shelley-genesis ${NODE_HOME}/config/mainnet-shelley-genesis.json --pool-stake ${POOL_STAKE} --active-stake ${ACTIVE_STAKE} --ledger-set ${LEDGER_SET_OPT})
echo ${MYPOOL} | jq .

EPOCH=$(echo ${MYPOOL} | jq .epoch)
echo "Epoch ${EPOCH} 🧙🔮:"

SLOTS=$(echo ${MYPOOL} | jq .epochSlots)
echo "SLOTS: ${SLOTS}"
IDEAL=`echo ${MYPOOL} | jq .epochSlotsIdeal`
echo "IDEAL: ${IDEAL}"
PERFORMANCE=`echo ${MYPOOL} | jq .maxPerformance`
echo "PERFORMANCE: ${PERFORMANCE}"

echo "MYPOOL - $SLOTS 🎰,  $PERFORMANCE% 🍀max, $IDEAL 🧱ideal"
