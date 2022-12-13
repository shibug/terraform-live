import pandas as pd
from blockfrost import BlockFrostApi, ApiError, ApiUrls


def delegator_wallet_address(staking_adddress):
    try:

        staker_address = api.account_addresses(stake_address = staking_adddress)
        #print(staker_address[-1].address)
        return staker_address[-1].address

    except ApiError as e:
        print(e)


def epoch_staked_on_pool(account_delegations,pool_id):
    for ad in account_delegations:
        print(ad.pool_id,ad.active_epoch)
        if ad.pool_id == pool_id:
            #print(ad.active_epoch)
            return ad.active_epoch


def epoch_unstaked_on_pool(account_delegations, pool_id):
    last_epoc = 'Current'
    for i in range(len(account_delegations) - 1, 0, -1):
        print(account_delegations[i])
        if account_delegations[i].pool_id == pool_id:
            break
        elif account_delegations[i].pool_id != pool_id:
            last_epoc = account_delegations[i].active_epoch
            # print(account_delegations[i].active_epoch)

    return last_epoc


def epoch_details(staking_address, pool_id):
    try:

        account_delegations = api.account_delegations(stake_address=staking_address)
        first_epoch = epoch_staked_on_pool(account_delegations, pool_id)
        last_epoch = epoch_unstaked_on_pool(account_delegations, pool_id)
        return [first_epoch, last_epoch]
    except ApiError as e:
        print(e)


def pigy_token_allocation(ada_staked):
    if ada_staked <= 10 : return 1000
    elif ada_staked <= 100 : return 2000
    elif ada_staked <= 1000 : return 3000
    elif ada_staked <= 10000 : return 5000
    elif ada_staked <= 100000 :return 10000


#Enter the Cardano Pool ID
pool_id = 'pool1jrn3nlmzt4r99fh5z450nnwqerwljzn426ffknfs9x8gcqgffst'

#Enter the BlockFrost API project ID
project_id = 'KjSHiUklMl92jG170Z0fsXjvQvJBxoV8'

api = BlockFrostApi(
    project_id= project_id,  # or export environment variable BLOCKFROST_PROJECT_ID
    # optional: pass base_url or export BLOCKFROST_API_URL to use testnet, defaults to ApiUrls.mainnet.value
    base_url=ApiUrls.mainnet.value,
)

# Getting the list of delegators

try:
    delegators = api.pool_delegators(pool_id=pool_id,page=1)

except ApiError as e:
    print(e)

print("Total Number of Delegators:{}".format(len(delegators)))

mylo = []
for delegator in delegators:
    delegator_details= {}
    if int(delegator.live_stake) >= 1000000000:        
        delegator_details['delegator_stake_key_id'] = delegator.address
        delegator_details['ada_staked'] = int(delegator.live_stake)/1000000
        delegator_details['delegator_address'] = delegator_wallet_address(delegator_details['delegator_stake_key_id'])
        epocs = epoch_details(delegator_details['delegator_stake_key_id'],pool_id)
        delegator_details['epoc_staked'] = epocs[0]
        delegator_details['epoc_unstaked'] = epocs[1]
        delegator_details['staked_rewards'] = delegator_details['ada_staked'] * 0.04
        # delegator_details['piggy_token_allocaion'] = pigy_token_allocation(delegator_details['ada_staked'])
        print(delegator_details)
        mylo.append(delegator_details)

df = pd.DataFrame(mylo)
print(df)

df.to_excel("Mylo_report.xlsx")