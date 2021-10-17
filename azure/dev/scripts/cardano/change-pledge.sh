#----------------------------------------------------------------------------------
# BLOCK PRODUCER NODE
#----------------------------------------------------------------------------------
cd $NODE_HOME/priv
dke cardano-bp bash
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
cd /opt/cardano/cnode/priv/

cardano-cli query protocol-parameters --mainnet --out-file params.json

cardano-cli stake-pool metadata-hash --pool-metadata-file poolMetaData.json > poolMetaDataHash.txt

cardano-cli query utxo --address $(cat payment.addr) --mainnet

currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
echo Current Slot: $currentSlot
cardano-cli query utxo --address $(cat payment.addr) --mainnet > fullUtxo.out
tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out
cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${total_balance} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.tmp

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee

txOut=$((${total_balance}-${fee}))
echo txOut: ${txOut}

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.raw

cardano-cli transaction submit --tx-file tx.signed --mainnet

#----------------------------------------------------------------------------------
# AIR-GAPPED NODE
#----------------------------------------------------------------------------------
cd /Users/shibugope/Dropbox/keys/cardano/mainnet
scp bp.cardano.mylo.farm:/data/cardano/priv/poolMetaDataHash.txt .

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.30.1 stake-pool registration-certificate \
    --cold-verification-key-file /keys/node.vkey \
    --vrf-verification-key-file /keys/vrf.vkey \
    --pool-pledge 25000000000 \
    --pool-cost 340000000 \
    --pool-margin 0.019 \
    --pool-reward-account-verification-key-file /keys/stake.vkey \
    --pool-owner-stake-verification-key-file /keys/stake.vkey \
    --mainnet \
    --single-host-pool-relay rly1.cardano.mylo.farm \
    --pool-relay-port 6000 \
    --single-host-pool-relay rly2.cardano.mylo.farm \
    --pool-relay-port 6000 \
    --metadata-url https://git.io/JuuuP \
    --metadata-hash $(cat poolMetaDataHash.txt) \
    --out-file /keys/pool.cert

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.30.1 stake-address delegation-certificate \
    --stake-verification-key-file /keys/stake.vkey \
    --cold-verification-key-file /keys/node.vkey \
    --out-file /keys/deleg.cert

scp pool.cert deleg.cert bp.cardano.mylo.farm:/data/cardano/priv/

scp bp.cardano.mylo.farm:/data/cardano/priv/tx.raw .

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.30.1 transaction sign \
    --tx-body-file /keys/tx.raw \
    --signing-key-file /keys/payment.skey \
    --signing-key-file /keys/node.skey \
    --signing-key-file /keys/stake.skey \
    --mainnet \
    --out-file /keys/tx.signed

scp tx.signed bp.cardano.mylo.farm:/data/cardano/priv/    