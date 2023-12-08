if [ x${ELASTIC_PASSWORD} == x ]; then
    echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
    exit 1;
elif [ x${KIBANA_PASSWORD} == x ]; then
    echo "Set the KIBANA_PASSWORD environment variable in the .env file";
    exit 1;
elif [ x${APM_SERVER_PASSWORD} == x ]; then
    echo "Set the APM_SERVER_PASSWORD environment variable in the .env file";
    exit 1;
fi;

if [ ! -f config/certs/ca.zip ]; then
    echo "Creating CA";
    bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
    unzip config/certs/ca.zip -d config/certs;
fi;

if [ ! -f config/certs/certs.zip ]; then
    echo "Creating certs";

    bin/elasticsearch-certutil cert --silent \
        --pem -out config/certs/certs.zip \
        --in /setup/instances.yml \
        --ca-cert config/certs/ca/ca.crt \
        --ca-key config/certs/ca/ca.key;

    unzip config/certs/certs.zip -d config/certs;

    echo "Setting file permissions"
fi;

chown -R 1000:1000 config/certs;
find . -type d -exec chmod 750 \{\} \;;
find . -type f -exec chmod 640 \{\} \;;

echo "Waiting for Elasticsearch availability";
until curl -s --cacert config/certs/ca/ca.crt https://elasticsearch:9200 | grep -q "missing authentication credentials"; do sleep 30; done;

echo "Setting kibana_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt \
    -u "elastic:${ELASTIC_PASSWORD}" \
    -H "Content-Type: application/json" https://elasticsearch:9200/_security/user/kibana_system/_password \
    -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;

echo "Setting apm_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt \
    -u "elastic:${ELASTIC_PASSWORD}" \
    -H "Content-Type: application/json" https://es01:9200/_security/user/apm_system/_password \
    -d "{\"password\":\"${APM_SERVER_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;

echo "All done!";