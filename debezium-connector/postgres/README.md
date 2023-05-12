# PostgreSQL Debezium Plugin with Secrets Manager Integration , JSON Output
## Build the package for MSK Connect Plugin
```
export source_root=`pwd`
mkdir debezium-connector-postgres-secret-manager
cd debezium-connector-postgres-secret-manager

git clone https://github.com/aws-samples/msk-config-providers.git
cd msk-config-providers 
mvn clean package -DskipTests
cp target/shade-uber/msk-config-providers-*-uber.jar ..
cd ..

wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.2.0.Final/debezium-connector-postgres-2.2.0.Final-plugin.zip
zip -Tvf debezium-connector-postgres-2.2.0.Final-plugin.zip

unzip debezium-connector-postgres-2.2.0.Final-plugin.zip
cp msk-config-providers-0.2.0-SNAPSHOT-uber.jar debezium-connector-postgres/
zip -r debezium-connector-postgres-secret-manager-2.2.0.Final-plugin.zip debezium-connector-postgres
zip -Tvf debezium-connector-postgres-secret-manager-2.2.0.Final-plugin.zip

```
## Create custom plugin
```shell
export custom_plugin_name=<<<custom_plugin_name>>>
export bucket_name=<<<bucket_name>>>
aws s3 cp debezium-connector-postgres-secret-manager-2.2.0.Final-plugin.zip s3://${bucket_name}/msk-connect-plugin/
cat << EOF > create-custom-plugin.json
{
    "name": "${custom_plugin_name}",
    "contentType": "ZIP",
    "location": {
        "s3Location": {
            "bucketArn": "arn:aws:s3:::${bucket_name}",
            "fileKey": "msk-connect-plugin/debezium-connector-postgres-secret-manager-2.2.0.Final-plugin.zip"
        }
    }
}
EOF
export custom_plugin_arn=$(aws kafkaconnect create-custom-plugin --cli-input-json file://create-custom-plugin.json --query customPluginArn --output text)
echo "Custom plugin ARN: ${custom_plugin_arn}"
```
## Create Worker Configuration
1. Refer the worker configuraiton template at [worker configuraiton template](templates/worker-configuration-secret-manager.properties) which showcases secret manager config provider. Apart form that it uses default schema registery and AVRO converte which could be overwritten by connectors. 
2. The worker configuration template at [SSM and secret manager configuration template](templates/worker-configuration.properties) shows how SSM can be used to read properties.
3. Use the sample below to create the worker configuration and use the ARN to create connectors subsequently. 
```shell
export worker_config_name=<<worker_config_name>>
export worker_properties_file=$source_root/debezium-connector/postgres/templates/worker-configuration-secret-manager.properties
cd $source_root
./create-worker-config.sh $worker_config_name $worker_properties_file 
export worker_config_arn=`cat worker_config_arn.txt`
echo "worker_config_arn=$worker_config_arn"
```
## Check connectivity 
```shell
## Ensure that there is ingress from self on these ports  
# 9092(if plain, no auth), 9094(if TLS,no auth), 9098(if TLS,IAM)
## Ensure that thers is Egress on all ports, all ip , or
## to self on 9092(if plain, no auth), 9094(if TLS,no auth), 9098(if TLS,IAM)
aws ec2 describe-security-groups  --group-ids $msk_security_group \
--query 'SecurityGroups[0].IpPermissions' --output table

aws ec2 describe-security-groups  --group-ids $msk_security_group \
--query 'SecurityGroups[0].IpPermissionsEgress' --output table

```
## Create the connector JSON output, TLS No Auth
1. Refer to the connector template [JSON no-auth connector tempalte](templates/debezium-postgres-secret-manager-json-noauth.json) which generates JSON output and connects on MSK on TLS without authentication.
2. Update the configuration and use the config to create the connector. 
3. The sample below uses the sample at [sample config](samples/debezium-postgres-secret-manager-json-noauth.json) to generate the connector. 
```shell
cd $source_root
export connector_config_file=$source_root/debezium-connector/postgres/samples/debezium-postgres-secret-manager-json-noauth.json
./create-connector.sh  ${connector_config_file} 

```

## Create the connector JSON output, IAM Auth
1. Refer to the connector template [JSON IAM auth connector template](templates/debezium-postgres-secret-manager-json-iam.json) which generates JSON output and connects on MSK on TLS without authentication.
2. Update the configuration and use the config to create the connector.
3. The sample below uses the sample at [sample config](samples/debezium-postgres-secret-manager-json-iam.json) to generate the connector.
```shell
cd $source_root
export connector_config_file=$source_root/debezium-connector/postgres/samples/debezium-postgres-secret-manager-json-iam.json
./create-connector.sh  ${connector_config_file} 

```


# PostgreSQL Debezium Plugin with Secrets Manager Integration , AVRO Output
## Create the custom plugin with Confluent Schema Registry
1. For AVRO output you need additional jar for AVRO connector. 
2. Use the instructions below to create the package. 
3. Once the package is created , use subsequent instructions to upload to S3 and create custom connector. 
```shell
cd $source_root
mkdir .debezium-connector-postgres-secret-manager-avro-confluent
cd .debezium-connector-postgres-secret-manager-avro-confluent

git clone https://github.com/aws-samples/msk-config-providers.git
cd msk-config-providers 
mvn clean package -DskipTests
cp target/shade-uber/msk-config-providers-*-uber.jar ..
cd ..

wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.2.0.Final/debezium-connector-postgres-2.2.0.Final-plugin.zip
zip -Tvf debezium-connector-postgres-2.2.0.Final-plugin.zip

unzip debezium-connector-postgres-2.2.0.Final-plugin.zip
cp msk-config-providers-0.2.0-SNAPSHOT-uber.jar debezium-connector-postgres/

wget https://packages.confluent.io/maven/io/confluent/kafka-connect-avro-converter/6.1.9/kafka-connect-avro-converter-6.1.9.jar -P debezium-connector-postgres/
wget https://packages.confluent.io/maven/io/confluent/kafka-connect-avro-data/6.1.9/kafka-connect-avro-data-6.1.9.jar -P debezium-connector-postgres/
wget https://packages.confluent.io/maven/io/confluent/kafka-avro-serializer/6.1.9/kafka-avro-serializer-6.1.9.jar -P debezium-connector-postgres/
wget https://packages.confluent.io/maven/io/confluent/kafka-schema-serializer/6.1.9/kafka-schema-serializer-6.1.9.jar -P debezium-connector-postgres/
wget https://packages.confluent.io/maven/io/confluent/kafka-schema-registry-client/6.1.9/kafka-schema-registry-client-6.1.9.jar -P debezium-connector-postgres/
wget https://packages.confluent.io/maven/io/confluent/common-config/6.1.9/common-config-6.1.9.jar -P debezium-connector-postgres/
wget https://packages.confluent.io/maven/io/confluent/common-utils/6.1.9/common-utils-6.1.9.jar -P debezium-connector-postgres/
wget https://repo1.maven.org/maven2/org/apache/avro/avro/1.11.0/avro-1.11.0.jar -P debezium-connector-postgres/
wget https://repo1.maven.org/maven2/com/google/guava/guava/31.1-jre/guava-31.1-jre.jar -P debezium-connector-postgres/
wget https://repo1.maven.org/maven2/com/google/protobuf/protobuf-java/3.22.0/protobuf-java-3.22.0.jar  -P debezium-connector-postgres/
wget https://repo1.maven.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar -P debezium-connector-postgres/

zip -r debezium-connector-postgres-secret-manager-avro-confluent-2.2.0.Final-plugin.zip debezium-connector-postgres
zip -Tvf debezium-connector-postgres-secret-manager-avro-confluent-2.2.0.Final-plugin.zip

```

1. Use the instructions below to create custom plugin which can create AVRO and use confluent schema registry. 
```shell
export bucket_name=<<<bucket_name>>>
export plugin_name=debezium-connector-postgres-secret-manager-avro-confluent-222
aws s3 cp debezium-connector-postgres-secret-manager-avro-confluent-2.2.0.Final-plugin.zip s3://${bucket_name}/msk-connect-plugin/

cat << EOF > create-custom-plugin.json
{
    "name": "${plugin_name}",
    "contentType": "ZIP",
    "location": {
        "s3Location": {
            "bucketArn": "arn:aws:s3:::${bucket_name}",
            "fileKey": "msk-connect-plugin/debezium-connector-postgres-secret-manager-avro-confluent-2.2.0.Final-plugin.zip"
        }
    }
}
EOF
cat create-custom-plugin.json
export custom_plugin_arn=$(aws kafkaconnect create-custom-plugin --cli-input-json file://create-custom-plugin.json --query customPluginArn --output text)
echo $custom_plugin_arn
```
## Create the connector AVRO output, Glue Schema Registry, IAM Auth
## Create the connector AVRO output, Confluent Schema Registry, IAM Auth
1. Refer to the connector template [AVRO IAM auth connector template](templates/debezium-postgres-secret-manager-avro-iam.json) which generates AVRO output and connects on MSK on TLS with IAM.
2. Update the configuration and use the config to create the connector.
3. The sample below uses the sample at [sample config](samples/debezium-postgres-secret-manager-avro-iam.json) to generate the connector.
```shell
cd $source_root
export connector_config_file=$source_root/debezium-connector/postgres/samples/debezium-postgres-secret-manager-avro-iam.json
./create-connector.sh  ${connector_config_file} 
```

# To DO
1. Check the topic prefix is unique. If not warn customers. The script can look at all the MSK connector and warn. 
2. Based on SG config check if MSK and MSK connect can talk to each other. 
3. 