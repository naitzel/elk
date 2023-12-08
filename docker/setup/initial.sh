
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