#Create a user-defined network
docker network create monitoring

#Run Prometheus
docker run -d -p 9090:9090 --name prometheus --restart on-failure:3 --security-opt="no-new-privileges=true" \
  -v /data/monitoring/prometheus/db:/prometheus -v /data/monitoring/prometheus/config.yml:/etc/prometheus/prometheus.yml \
  --network monitoring --health-cmd='wget -qO- localhost:9090/status || exit 1' --health-start-period=3m \
  prom/prometheus:v2.30.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.console.templates=/etc/prometheus/consoles \
  --web.external-url=http://status.mylo.farm:9090 \
  --storage.tsdb.retention.time=30d

#Run Grafana
docker run -d -p 80:3000 --name grafana --restart on-failure:3 --security-opt="no-new-privileges=true" \
  -v /data/monitoring/grafana/db:/var/lib/grafana -v /data/monitoring/grafana/admin_password:/run/secrets/grafana_admin_password \
  -e GF_SERVER_DOMAIN=mylo.farm \
  -e GF_SERVER_ROOT_URL=http://status.mylo.farm \
  -e GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password \
  -e GF_USERS_ALLOW_ORG_CREATE=false \
  -e GF_SESSION_COOKIE_SECURE=true \
  -e GF_AUTH_ANONYMOUS_ENABLED=true \
  -e GF_AUTH_ANONYMOUS_ORG_NAME="Mylo Farm" \
  -e GF_AUTH_ANONYMOUS_ORG_ROLE="Viewer" \
  --network monitoring --health-cmd='wget -qO- localhost:3000/metrics || exit 1' \
  grafana/grafana:8.1.5
