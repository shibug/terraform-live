docker build . -t cardanocommunity/cardano-node:stage1 -f files/docker/node/dockerfile_stage1
docker build . -t cardanocommunity/cardano-node:stage2 -f files/docker/node/dockerfile_stage2
docker build . -t cardanocommunity/cardano-node:stage3 -f files/docker/node/dockerfile_stage3