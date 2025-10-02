
#!/bin/bash

# Kafka broker adresi
KAFKA_BROKER="kafka:9092"

# Oluşturulacak topic listesi
TOPICS=("connect-status" "connect-configs" "connect-offsets")

# Topic için partition ve replication factor
PARTITIONS=1
REPLICATION_FACTOR=1

# Eğer topic adı verilmediyse, hata mesajı verir
#if [ -z "$TOPIC_NAME" ]; then
#  echo "Hata: Lütfen bir topic adı girin."
#  exit 1
#fi

# # Kafka topic oluşturma komutu
# echo "Topic '$TOPIC_NAME' oluşturuluyor..."

# # Kafka topic oluşturma
# kafka-topics --create --bootstrap-server "$KAFKA_BROKER"   --replication-factor "$REPLICATION_FACTOR"   --partitions "$PARTITIONS"   --config cleanup.policy=compact   --topic "$TOPIC_NAME"
# #/kafka/bin/kafka-topics.sh --create --topic "$TOPIC_NAME" --bootstrap-server "$KAFKA_BROKER" --partitions "$PARTITIONS" --replication-factor "$REPLICATION_FACTOR"

# # Kontrol etme
# if [ $? -eq 0 ]; then
  # echo "Topic '$TOPIC_NAME' başarıyla oluşturuldu."
# else
  # echo "Topic '$TOPIC_NAME' oluşturulamadı."
# fi

# Kafka topic'lerini oluşturmak için döngü
for TOPIC_NAME in "${TOPICS[@]}"; do
  echo "Topic '$TOPIC_NAME' oluşturuluyor..."

  # Docker container içinde topic oluşturma
  #docker exec $KAFKA_CONTAINER /bin/bash -c "/kafka/bin/kafka-topics.sh --create --topic $TOPIC_NAME --bootstrap-server $KAFKA_BROKER --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR"

  #kafka-topics --create --bootstrap-server "$KAFKA_BROKER"   --replication-factor "$REPLICATION_FACTOR"   --partitions "$PARTITIONS"   --config cleanup.policy=compact   --topic "$TOPIC_NAME"
  /kafka/bin/kafka-topics.sh --create --topic "$TOPIC_NAME" --bootstrap-server "$KAFKA_BROKER" --partitions "$PARTITIONS" --replication-factor "$REPLICATION_FACTOR"   --config cleanup.policy=compact


  # Başarı kontrolü
  if [ $? -eq 0 ]; then
    echo "Topic '$TOPIC_NAME' başarıyla oluşturuldu."
  else
    echo "Topic '$TOPIC_NAME' oluşturulamadı."
  fi
done






#kafka-topics --create --bootstrap-server kafka:9092   --replication-factor 1   --partitions 1   --config cleanup.policy=compact   --topic connect-status
#kafka-topics --create --bootstrap-server kafka:9092   --replication-factor 1   --partitions 1   --config cleanup.policy=compact   --topic connect-configs
#kafka-topics --create --bootstrap-server kafka:9092   --replication-factor 1   --partitions 1   --config cleanup.policy=compact   --topic connect-offsets
