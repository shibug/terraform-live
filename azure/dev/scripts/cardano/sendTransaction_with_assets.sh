#-----------------------------------------------------------
# RUN ON BLOCK PRODUCER NODE
#-----------------------------------------------------------   

cd /opt/cardano/cnode/priv/ 
export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket

# Get protocol parameters
cardano-cli query protocol-parameters --mainnet --out-file params.json

amountToSend=10000000
echo amountToSend: $amountToSend

destinationAddress="addr1q95jcluf5wkg227s4fn8gq6phnk54euc4h4e4pnudfk3qzyhay7stu55slw4d00hnjaaj2d3k6rd8zc6u2qtwhxfwcpqv9nkd0"
echo destinationAddress: $destinationAddress

# Get the transaction hash and index of the UTXO to spend
cardano-cli query utxo --address $(cat payment.addr) --mainnet > fullUtxo.out
tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out
cat balance.out

# Draft the transaction
tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
tx_cnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${tx_cnt}
echo Transaction Input: ${tx_in}

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${destinationAddress}+${amountToSend}+"1000000 a0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235.484f534b59"+"1000000000 af2e27f580f7f08e93190a81f72462f153026d06450924726645891b.44524950"+"50000000 edfd7a1d77bcb8b884c474bdc92a16002d1fb720e454fa6e99344479.4e5458"+"1 f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a.6d796c6f" \
    --tx-out $(cat payment.addr)+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file tx.tmp

# Calculate the fee
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${tx_cnt} \
    --tx-out-count 2 \
    --witness-count 1 \
    --byron-witness-count 0 \
    --mainnet \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee

# Calculate your change output
chg_out=$((${total_balance}-${fee}-${amountToSend}))
echo Change Output: ${chg_out}

# Determine the TTL (time to Live) for the transaction
currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
echo Current Slot: $currentSlot
TTL=$(( ${currentSlot} + 300))
echo TTL: ${TTL}

# Build your transaction
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out ${destinationAddress}+${amountToSend}+"1000000 a0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235.484f534b59"+"1000000000 af2e27f580f7f08e93190a81f72462f153026d06450924726645891b.44524950"+"50000000 edfd7a1d77bcb8b884c474bdc92a16002d1fb720e454fa6e99344479.4e5458"+"1 f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a.6d796c6f" \
    --tx-out $(cat payment.addr)+${chg_out} \
    --invalid-hereafter ${TTL} \
    --fee ${fee} \
    --out-file tx.raw

#-----------------------------------------------------------
# RUN ON AIR GAPPED OFFLINE MACHINE
#-----------------------------------------------------------    
# Copy tx.raw to your cold environment.
# Sign the transaction with the payment secret key. 

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.35.4 transaction sign \
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
