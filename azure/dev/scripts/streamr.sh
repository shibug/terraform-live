#Configure
docker run -it -v $(cd /data/streamr; pwd):/home/streamr/.streamr streamr/broker-node:latest bin/config-wizard

#Run
docker run -d --name streamr-broker \
--restart on-failure:3 --security-opt="no-new-privileges=true" \
--env NODE_ENV=production \
-p 7170:7170 -p 7171:7171 -p 1883:1883 \
-v $(cd /data/streamr && pwd):/home/streamr/.streamr \
streamr/broker-node:latest