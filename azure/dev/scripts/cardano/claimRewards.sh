#-----------------------------------------------------------
# RUN ON BLOCK PRODUCER NODE
#-----------------------------------------------------------    
cd /opt/cardano/cnode/priv/
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
echo Current Slot: $currentSlot

rewardBalance=$(cardano-cli query stake-address-info \
    --mainnet \
    --address $(cat stake.addr) | jq -r ".[0].rewardAccountBalance")
echo rewardBalance: $rewardBalance

destinationAddress=addr1qxpsa4spmwdyr5a2l4v4mhgmrp09cpdzkvv67lxmeyqu9tenx4nu9t6036n3zgpq6qdsykk30rd6c5hk3qc8yqslt97qq0sngh
echo destinationAddress: $destinationAddress

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

withdrawalString="$(cat stake.addr)+${rewardBalance}"

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --withdrawal ${withdrawalString} \
    --out-file tx.tmp

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee

txOut=$((${total_balance}-${fee}+${rewardBalance}))
echo Change Output: ${txOut}

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --withdrawal ${withdrawalString} \
    --out-file tx.raw

#-----------------------------------------------------------
# RUN ON AIR GAPPED OFFLINE MACHINE
#-----------------------------------------------------------  
# Copy tx.raw to your cold environment.
# Sign the transaction with both the payment and stake secret keys. 

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.34.1 transaction sign \
    --tx-body-file /keys/tx.raw \
    --signing-key-file /keys/payment.skey \
    --signing-key-file /keys/stake.skey \
    --mainnet \
    --out-file /keys/tx.signed

#-----------------------------------------------------------
# RUN ON BLOCK PRODUCER NODE
#-----------------------------------------------------------    
# Copy tx.signed to your hot environment.
# Send the signed transaction.

cardano-cli transaction submit \
    --tx-file tx.signed \
    --mainnet

cardano-cli query utxo \
    --address ${destinationAddress} \
    --mainnet    
