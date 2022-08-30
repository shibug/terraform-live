#-----------------------------------------------------------
# RUN ON BLOCK PRODUCER NODE
#-----------------------------------------------------------   
cd /opt/cardano/cnode/priv/ 
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
echo Current Slot: $currentSlot

amountToSend=10404000000
echo amountToSend: $amountToSend

destinationAddress=addr1qxzzhf6d9mzdekfchz2vrnqt0q3r4r994n9k8s38xqse9xuhay7stu55slw4d00hnjaaj2d3k6rd8zc6u2qtwhxfwcpqfx9dn9
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

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+0 \
    --tx-out ${destinationAddress}+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file tx.tmp

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 2 \
    --mainnet \
    --witness-count 1 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee

# Calculate your change output
txOut=$((${total_balance}-${fee}-${amountToSend}))
echo Change Output: ${txOut}

#Build your transaction
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --tx-out ${destinationAddress}+${amountToSend} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --out-file tx.raw

#-----------------------------------------------------------
# RUN ON AIR GAPPED OFFLINE MACHINE
#-----------------------------------------------------------    
# Copy tx.raw to your cold environment.
# Sign the transaction with the payment secret key. 

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.35.3 transaction sign \
    --tx-body-file /keys/tx.raw \
    --signing-key-file /keys/payment.skey \
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
