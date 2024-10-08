#!/bin/bash
./checkout-build-dependent.sh
mvn clean install -DskipTests -f pom-debezium-connector-postgres-aws-config.xml
mvn clean install -DskipTests -f pom-debezium-connector-postgres-gsr-avro.xml
mvn clean install -DskipTests -f pom-debezium-connector-postgres-gsr-protobuf.xml
mvn clean install -DskipTests -f pom-debezium-connector-postgres-confluent.xml
