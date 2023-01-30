#----------------------------------------------------------------------------------
# COMMON
#----------------------------------------------------------------------------------
#8. Start the nodes
docker run -d -h bp.cardano.mylo.farm --name cardano-bp -p 6000:6000 -p 12781:12781 -p 12798:12798 --restart on-failure:3 \
    --security-opt="no-new-privileges=true" -e NETWORK=mainnet -e POOL_DIR=/opt/cardano/cnode/priv \
    -v /data/cardano/sockets:/opt/cardano/cnode/sockets -v /data/cardano/priv:/opt/cardano/cnode/priv \
    -v /data/cardano/db:/opt/cardano/cnode/db -v /data/cardano/logs:/opt/cardano/cnode/logs \
    -v /data/cardano/config/mainnet-topology.json:/opt/cardano/cnode/files/topology.json \
    -v /data/cardano/config/mainnet-config.json:/opt/cardano/cnode/files/config.json \
    -v /data/cardano/scripts/guild-deploy.sh:/opt/cardano/cnode/scripts/guild-deploy.sh shibug/cardano-node:1.35.5

dke cardano-bp /opt/cardano/cnode/scripts/gLiveView.sh

docker run -d -h rly1.cardano.mylo.farm --name cardano-rly1 -p 6000:6000 -p 12781:12781 -p 12798:12798 --restart on-failure:3 \
    --security-opt="no-new-privileges=true" -e NETWORK=mainnet -v /data/cardano/sockets:/opt/cardano/cnode/sockets \
    -v /data/cardano/db:/opt/cardano/cnode/db -v /data/cardano/logs:/opt/cardano/cnode/logs -v /data/cardano/temp:/opt/cardano/cnode/temp \
    -v /data/cardano/config/mainnet-topology.json:/opt/cardano/cnode/files/topology.json \
    -v /data/cardano/scripts/topologyUpdater.sh:/opt/cardano/cnode/scripts/topologyUpdater.sh \
    -v /data/cardano/scripts/guild-deploy.sh:/opt/cardano/cnode/scripts/guild-deploy.sh shibug/cardano-node:1.35.5

dke cardano-rly1 /opt/cardano/cnode/scripts/gLiveView.sh

docker run -d -h rly2.cardano.mylo.farm --name cardano-rly2 -p 6000:6000 -p 12781:12781 -p 12798:12798 --restart on-failure:3 \
    --security-opt="no-new-privileges=true" -e NETWORK=mainnet -v /data/cardano/sockets:/opt/cardano/cnode/sockets \
    -v /data/cardano/db:/opt/cardano/cnode/db -v /data/cardano/logs:/opt/cardano/cnode/logs -v /data/cardano/temp:/opt/cardano/cnode/temp \
    -v /data/cardano/config/mainnet-topology.json:/opt/cardano/cnode/files/topology.json \
    -v /data/cardano/scripts/topologyUpdater.sh:/opt/cardano/cnode/scripts/topologyUpdater.sh shibug/cardano-node:1.35.5

# Submit API
docker run -d --name submit-api --restart on-failure:3 -p 8090:8090 --security-opt="no-new-privileges=true" \
    -v /data/cardano/sockets:/opt/cardano/ipc shibug/cardano-submit-api:1.35.4-0.1.1   

dke cardano-rly2 /opt/cardano/cnode/scripts/gLiveView.sh

#----------------------------------------------------------------------------------
# BLOCK PRODUCER NODE
#----------------------------------------------------------------------------------
#9. Generate block-producer keys
cd $NODE_HOME/priv
cardano-cli node key-gen-KES --verification-key-file kes.vkey --signing-key-file kes.skey

export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
slotsPerKESPeriod=$(cat /opt/cardano/cnode/files/genesis.json | jq -r '.slotsPerKESPeriod')
echo slotsPerKESPeriod: ${slotsPerKESPeriod}
slotNo=$(cardano-cli query tip --mainnet | jq -r '.slot')
echo slotNo: ${slotNo}
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
echo kesPeriod: ${kesPeriod}
startKesPeriod=${kesPeriod}
echo startKesPeriod: ${startKesPeriod}

cardano-cli node key-gen-VRF --verification-key-file vrf.vkey --signing-key-file vrf.skey
chmod 400 vrf.skey

mv kes.skey hot.skey
mv node.cert op.cert

#10 Setup payment and stake keys
cardano-cli query protocol-parameters --mainnet --out-file params.json
cardano-cli query utxo --address $(cat payment.addr) --mainnet

#11 Register your stake address
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

stakeAddressDeposit=$(cat params.json | jq -r '.stakeAddressDeposit')
echo stakeAddressDeposit : $stakeAddressDeposit

cardano-cli transaction build-raw ${tx_in} --tx-out $(cat payment.addr)+0 --invalid-hereafter $(( ${currentSlot} + 10000)) --fee 0 --out-file tx.tmp --certificate stake.cert

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee

txOut=$((${total_balance}-${stakeAddressDeposit}-${fee}))
echo Change Output: ${txOut}

cardano-cli transaction build-raw ${tx_in} --tx-out $(cat payment.addr)+${txOut} --invalid-hereafter $(( ${currentSlot} + 10000)) --fee ${fee} --certificate-file stake.cert --out-file tx.raw

cardano-cli transaction submit --tx-file tx.signed --mainnet

#12 Register your stake pool
cardano-cli stake-pool metadata-hash --pool-metadata-file poolMetaData.json > poolMetaDataHash.txt

minPoolCost=$(cat $NODE_HOME/params.json | jq -r .minPoolCost)
echo minPoolCost: ${minPoolCost}

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

stakePoolDeposit=$(cat params.json | jq -r '.stakePoolDeposit')
echo stakePoolDeposit: $stakePoolDeposit

cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+$(( ${total_balance} - ${stakePoolDeposit}))  \
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

txOut=$((${total_balance}-${stakePoolDeposit}-${fee}))
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

#13 Locate your Stake pool ID and verify everything is working
cardano-cli query stake-snapshot --stake-pool-id $(cat stakepoolid.txt) --mainnet 

#----------------------------------------------------------------------------------
# AIR-GAPPED NODE
#----------------------------------------------------------------------------------
docker pull shibug/cardano-node:1.31.0
dki --entrypoint cardano-cli shibug/cardano-node:1.31.0 --version

#9 Generate block-producer keys
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 node key-gen --cold-verification-key-file /keys/node.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 node issue-op-cert --kes-verification-key-file /keys/kes.vkey --cold-signing-key-file /keys/node.skey --operational-certificate-issue-counter /keys/node.counter --kes-period 233 --out-file /keys/node.cert

#10 Setup payment and stake keys
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 address key-gen --verification-key-file /keys/payment.vkey --signing-key-file /keys/payment.skey
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address key-gen --verification-key-file /keys/stake.vkey --signing-key-file /keys/stake.skey
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address build --stake-verification-key-file /keys/stake.vkey --out-file /keys/stake.addr --mainnet
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 address build --payment-verification-key-file /keys/payment.vkey --stake-verification-key-file /keys/stake.vkey --out-file /keys/payment.addr --mainnet
scp payment.addr bp.cardano.mylo.farm:/data/cardano/priv/

#11 Register your stake address
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address registration-certificate --stake-verification-key-file /keys/stake.vkey --out-file /keys/stake.cert
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 transaction sign --tx-body-file /keys/tx.raw --signing-key-file /keys/payment.skey --signing-key-file /keys/stake.skey --mainnet --out-file /keys/tx.signed

#12 Register your stake pool
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-pool registration-certificate \
    --cold-verification-key-file /keys/node.vkey \
    --vrf-verification-key-file /keys/vrf.vkey \
    --pool-pledge 5000000000 \
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

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-address delegation-certificate \
    --stake-verification-key-file /keys/stake.vkey \
    --cold-verification-key-file /keys/node.vkey \
    --out-file /keys/deleg.cert

dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 transaction sign \
    --tx-body-file /keys/tx.raw \
    --signing-key-file /keys/payment.skey \
    --signing-key-file /keys/node.skey \
    --signing-key-file /keys/stake.skey \
    --mainnet \
    --out-file /keys/tx.signed

#13 Locate your Stake pool ID and verify everything is working
dki -v $PWD:/keys --entrypoint cardano-cli shibug/cardano-node:1.31.0 stake-pool id --cold-verification-key-file /keys/node.vkey --output-format hex > stakepoolid.txt
cat stakepoolid.txt 

#----------------------------------------------------------------------------------
# RELAY NODE
#----------------------------------------------------------------------------------
#14. Configure your topology files

#Add to /etc/crontab the following line
13 * * * * groot docker exec -i cardano-rly1 /opt/cardano/cnode/scripts/topologyUpdater.sh
23 * * * * groot docker exec -i cardano-rly2 /opt/cardano/cnode/scripts/topologyUpdater.sh

#Change cron.daily schedule in crontab to be 12 hours apart

#Create a file: /etc/cron.daily/cardano-relay and add the content below:
#!/bin/sh -e
# Update topology file and restart relay container
mv -f /data/cardano/temp/topology.json /data/cardano/config/mainnet-topology.json > /var/log/cardano-relay.log 2>&1
docker restart cardano-rly1 >> /var/log/cardano-relay.log 2>&1

#chmod +x /etc/cron.daily/cardano-relay

#----------------------------------------------------------------------------------
# MISCELLENEOUS
#----------------------------------------------------------------------------------
#How to delete files older than 3 days
find /data/cardano/logs/* -mtime +3 -exec ls -ltr {} \;
find /data/cardano/logs/* -mtime +3 -exec rm {} \;

#How to extend disk size
Stop the VM.
Increase the size of the OS disk from the portal.
Restart the VM, and then sign in to the VM as a root user.
dps
sudo -s
systemctl stop docker
systemctl status docker
df -Th
mount | grep "/dev/sdb"
umount /dev/sdb1
mount | grep "/dev/sdb"
df -Th
parted /dev/sdb
    print
    Fix
    rm 1
    mkpart ext4part 1049kB 100%
    print
    quit
e2fsck -f /dev/sdb1
resize2fs /dev/sdb1
mount | grep "/dev/sdb"
mount -av
mount | grep "/dev/sdb"