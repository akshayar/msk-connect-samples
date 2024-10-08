#!/bin/bash
## Parameters
export REGION=ap-south-1
export DATABASE_SG=sg-0ed52bb95436b45a3
export SUBNET_1=subnet-04113fd1c1192d77b
export SUBNET_2=subnet-048690b5d447e239d
export CUSTOM_PLUGIN_ARN=arn:aws:kafkaconnect:ap-south-1:ACCOUNT_ID:custom-plugin/debezium-connector-mysql-secret-manager-avro-confluent-2/f1f109dd-2dc3-4a2f-a163-e1d3e81383e9-4
export WORKER_CONFIG_ARN=arn:aws:kafkaconnect:ap-south-1:ACCOUNT_ID:worker-configuration/debezium-connector-mysql/66dfe795-9cb1-4fed-bd05-3da58c809923-4
export PLUGIN_SOURCE_BUCKET=aksh-code-binaries-2
export LOG_GROUP_NAME=/aws/msk-connect-mysql
export SCHEMA_REGISTRY_URL=http://ip-10-0-18-176.ap-south-1.compute.internal:8081

#export MSK_CLUSTER_BOOTSTRAP="b-3.mskdestinationcluster.09lu4s.c4.kafka.ap-south-1.amazonaws.com:9094,b-1.mskdestinationcluster.09lu4s.c4.kafka.ap-south-1.amazonaws.com:9094,b-2.mskdestinationcluster.09lu4s.c4.kafka.ap-south-1.amazonaws.com:9094"
#export TEMPLATE_FILE=templates/debezium-mysql-secret-manager-avro-tls.yml
#export CONNECTOR_NAME=debezium-mysql-secret-manager-avro-tlsp
#export TOPIC_PREFIX=mskconnnectmysqlavrotls

export MSK_CLUSTER_SG=sg-0ef20b19ad187614d
export MSK_CLUSTER_BOOTSTRAP="b-3.mskdestinationcluster.hrmyfq.c4.kafka.ap-south-1.amazonaws.com:9092,b-1.mskdestinationcluster.hrmyfq.c4.kafka.ap-south-1.amazonaws.com:9092,b-2.mskdestinationcluster.hrmyfq.c4.kafka.ap-south-1.amazonaws.com:9092"
export TEMPLATE_FILE=templates/debezium-mysql-secret-manager-avro-plaintext.yml
export CONNECTOR_NAME=mysql-secret-manager-avro-plaintext
export TOPIC_PREFIX=mskconnnectmysqlavroplaintext

aws logs create-log-group --log-group-name ${LOG_GROUP_NAME} --region ${REGION}

aws cloudformation deploy --template-file ${TEMPLATE_FILE} \
     --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
     --stack-name ${CONNECTOR_NAME} \
     --region ${REGION} \
     --disable-rollback \
     --parameter-overrides SubnetAId=${SUBNET_1} \
     SubnetBId=${SUBNET_2} \
     MSKClusterSG=${MSK_CLUSTER_SG} \
     DatabaseSG=${DATABASE_SG} \
     MSKClusterBootstrap=${MSK_CLUSTER_BOOTSTRAP} \
     TopicPrefix=${TOPIC_PREFIX} \
     DatabaseIncludeList=mydb \
     DBDetailsSecretName=rds-msk-connect \
     SchemaRegistryUrl=${SCHEMA_REGISTRY_URL} \
     ConnectorName=${CONNECTOR_NAME} \
     MSKConnectConnectorLogGroup=${LOG_GROUP_NAME} \
     WorkerConfigurationArn=${WORKER_CONFIG_ARN} \
     CustomPluginArn=${CUSTOM_PLUGIN_ARN} \
     PluginBucketName=${PLUGIN_SOURCE_BUCKET}