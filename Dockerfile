FROM azul/zulu-openjdk-alpine:11 AS maker

RUN apk add maven git openssh

RUN \
git clone https://github.com/forcedotcom/dataloader.git --branch v49.0.0 --single-branch  --depth 1 && \
cd dataloader && \
git submodule init && \
git submodule update && \
mvn clean package -DskipTests

FROM azul/zulu-openjdk-alpine:11

COPY --from=maker /dataloader/target/dataloader-49.0.0-uber.jar /dataloader.jar

CMD \ 
DATESTAMP=$(date +${TIMESTAMP_FORMAT}) && \ 
java -cp /dataloader.jar \
  -Dsalesforce.config.dir=/mnt/config \
  com.salesforce.dataloader.process.ProcessRunner \
  process.name=${JOB_NAME} \
  sfdc.username=${USERNAME} \
  sfdc.password=${ENCRYPTED_PASSWORD} \
  sfdc.endpoint=${URL} \
  process.encryptionKeyFile=/mnt/config/dataLoader.key \
  process.mappingFile=/mnt/config/mappings/${JOB_MAPPING_FILENAME} \
  process.statusOutputDirectory=/mnt/jobs/${DATESTAMP}/status/ \
  process.outputSuccess=/mnt/jobs/${DATESTAMP}/status/success.csv \
  process.outputError=/mnt/jobs/${DATESTAMP}/status/error.csv \
  dataAccess.name=/mnt/jobs/${DATESTAMP}/source.csv \
  sfdc.debugMessagesFile=/mnt/jobs/${DATESTAMP}/status/debug.log && \
java -cp /dataloader.jar \
  com.salesforce.dataloader.process.ProcessRunner \
  sfdc.entity=${ERRORLOGS_ENTITY_NAME} \
  sfdc.endpoint=${URL} \
  sfdc.username=${USERNAME} \
  sfdc.password=${ENCRYPTED_PASSWORD} \
  process.encryptionKeyFile=/mnt/config/${ENCRYPTION_KEY_FILENAME} \
  process.mappingFile=/mnt/config/mappings/${ERRORLOGS_MAPPING_FILENAME} \
  dataAccess.name=/mnt/jobs/${DATESTAMP}/status/error.csv \
  sfdc.debugMessages=false \
  process.enableLastRunOutput=false \
  process.enableExtractStatusOutput=false \
  sfdc.timeoutSecs=600 \
  sfdc.loadBatchSize=200 \
  process.operation=insert \
  dataAccess.type=csvRead