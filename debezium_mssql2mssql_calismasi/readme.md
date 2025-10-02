
# Debezium ile MSSQL'den MSSQL'e veri aktarımı

# 1. Veritabanlarının kurulumları

Öncelikle 2_mssql klasörünün altındaki docker-compose.yml dosyasını aşağıdaki kod ile çalıştırın.
```
docker-compose up -d
```
kaldırmak isterseniz alttaki kodu çalıştırın."-v" parametresi ile oluşan volume'leri de siler.
```
docker-compose down -v
```
Sonrasında src tarafında "eticaret_src.sql" dosyasını çalıştırın. dst tarafında ise "eticaret_dst.sql" dosyasını çalıştırın. 2 adet farklı isimde veritabanı oluşmuş oldu. src tarafında gerekli tabloları ve dataları oluşturmuş olduk.
Sonraki işlem src tarafında cdc özelliğini aktif etmek gerekiyor.
src tarafında çalıştırılması gereken scripler alttadır.
```
EXEC sys.sp_cdc_enable_db;

-- Order tablosu için
EXEC sys.sp_cdc_enable_table  
    @source_schema = N'dbo',  
    @source_name   = N'Order',  
    @role_name     = NULL

-- Order_Detail tablosu için
EXEC sys.sp_cdc_enable_table  
    @source_schema = N'dbo',  
    @source_name   = N'Order_Detail',  
    @role_name     = NULL;

-- Product tablosu için
EXEC sys.sp_cdc_enable_table  
    @source_schema = N'dbo',  
    @source_name   = N'Product',  
    @role_name     = NULL;
```
Gördüğünüz üzerinde tablo bazında da aktif etmek gerekiyor.
Disable etmek için de şöyle bir işlem yapılabilir.
```
EXEC sys.sp_cdc_disable_table
   @source_schema = N'dbo',
   @source_name   = N'Order',
   @capture_instance = N'dbo_Order'

    
EXEC sys.sp_cdc_disable_table
   @source_schema = N'dbo',
   @source_name   = N'Order_Detail',
   @capture_instance = N'dbo_Order_Detail'

    
EXEC sys.sp_cdc_disable_table
   @source_schema = N'dbo',
   @source_name   = N'Product',
   @capture_instance = N'dbo_Product'


EXEC sys.sp_cdc_disable_db
GO
```

eğer ki src tarafında ilgili tablolara sütun eklersek veya sütun çıkarırsak, tablo bazında cdc özelliğini iptal edip ardından tekrar aktif hale getirmeliyiz. Yoksa ilgili sütun diğer tarafa etki etmez. sütun eklediğimiz durumda dst tarafında da ilgili sütun ekleniyor. ancak silme işleminde sizin kendinizin silmesi gerekiyor. Ekleme işleminde sütunun diğer tarafada eklenmesi için, ilgili sütun ile ilgili işlem yapılmalı.

Product tablosunun capture edilmiş kolonlarını aşağıdaki sorgu ile öğrenebilirsiniz.
```
EXEC sys.sp_cdc_get_captured_columns 'dbo_Product';
```

# 2. Debezium Kurulumu
Debezium klasörünün içindeki docker-compose.yml dosyasının aşağıdaki gibi çalıştırılması gerekiyor.
```
docker-compose up -d
```
kaldırmak isterseniz alttaki kodu çalıştırın."-v" parametresi ile oluşan volume'leri de siler.
```
docker-compose down -v
```

Sonrasında kafka tarafında aşağıdaki topic'ler oluşmamışsa, sizin oluşturmanız gerekiyor. Bunun scripti de aşağıdaki gibi.
```
docker exec -it kafka bash

kafka-topics --create --bootstrap-server kafka:9092   --replication-factor 1   --partitions 1   --config cleanup.policy=compact   --topic connect-status

kafka-topics --create --bootstrap-server kafka:9092   --replication-factor 1   --partitions 1   --config cleanup.policy=compact   --topic connect-configs

kafka-topics --create --bootstrap-server kafka:9092   --replication-factor 1   --partitions 1   --config cleanup.policy=compact   --topic connect-offsets

exit

//connect container'ı restart ediliyor.
docker restart connect 

```
örnek olması ve gerek görülmesi için aşağıdaki scriptleri de paylaşıyorum.
```
docker exec -it kafka bash

kafka-topics --delete  --bootstrap-server localhost:9092 --topic schema-changes.sqlserver

kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic schema-changes.eticaret --config cleanup.policy=compact

exit
```

Sonrasında debeziumda source connector tanımını yapmak için aşağıdaki sorguyu curl ile çalıştırıyoruz.

```
database.hostname -> Kaynak SQL Server adresi (Docker içinden dışarıya host.docker.internal)
table.include.list -> Sadece bu 3 tablo için veri aktarımı yapılacak
database.server.name -> Kafka topic adlarını belirleyecek (örn: mssql_src.dbo.Product)
database.history.kafka.* -> Şema değişikliklerini takip edecek (internal topic)
```
Başarılı olursa her tablo için Kafka'da şu topic'ler oluşur:
	mssql_src.dbo.Product, mssql_src.dbo.Product, mssql_src.dbo.Order_Detail
```
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "mssql-source-connector",
  "config": {
    "connector.class": "io.debezium.connector.sqlserver.SqlServerConnector",
    "database.encrypt": "true",
    "database.trustServerCertificate": "true",
    "database.hostname": "host.docker.internal",
    "database.names": "eticaret",
    "database.port": "1433",
    "database.user": "sa",
    "database.password": "YourStrong@Password1",
    "table.include.list": "dbo.Order,dbo.Order_Detail,dbo.Product",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "schema-changes.eticaret",
    "include.schema.changes": "false",
    "topic.prefix": "mssql_src",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "true",
    "schema.history.internal.consumer.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
    "schema.history.internal.kafka.topic": "eticaret.debezium-schema-history",
    "schema.history.internal.producer.bootstrap.servers": "kafka:9092",
    "snapshot.isolation.mode": "read_committed",
    "snapshot.mode": "initial",
    "incremental.snapshot.enabled": "true",
    "time.precision.mode": "connect",
    "timestamp.handling.mode": "string",
    "tombstones.on.delete": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "true"
  }
}'

```
sonrasında kontrol etmek amacıyla
Tarayıcıdan http://localhost:8080 (Kafka UI) ile topic’leri görebilirsin.
veya
cli ile aşağıdaki komut çalıştırılır
```
docker exec -it kafka kafka-topics --bootstrap-server kafka:9092 --list
```

Hedefe Aktarma (dst veritabanı)
burda 2 yöntem var. 
* 1.si Bir mikroservis (Python, Node.js, .NET, Java) yazarak, Kafka’dan Product, Order, Order_Detail konularını okursun
* 2.si Kafka → MSSQL Sink Connector (Otomatik Replikasyon) (daha karmaşık ama otomatik)
2.sinde connectorları indirmek lazım


sonrasında sink connector tanımı yapılacak
```
topics -> Kafka’dan dinlenecek topic listesi (Debezium’un yazdığı topic’ler)
insert.mode=upsert -> Aynı primary key varsa UPDATE, yoksa INSERT yapar
pk.mode=record_key -> Debezium key'i Kafka mesajının key kısmında taşır
pk.fields=Id -> Tablolarda primary key olarak kullanılan alan
auto.create=true -> Hedefte tablo yoksa otomatik olarak oluşturur
auto.evolve=true -> Şema değişirse tabloyu günceller
kafka:9092 --list
```
```
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "mssql-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "topics": "mssql_src.eticaret.dbo.Product,mssql_src.eticaret.dbo.Order,mssql_src.eticaret.dbo.Order_Detail",
    "consumer.override.auto.offset.reset": "earliest",
    "consumer.override.group.id": "eticaret.group.db.mssql",
    "connection.url": "jdbc:sqlserver://host.docker.internal:1434;databaseName=eticaret_dst;user=sa;password=YourStrong@Password1;encrypt=true;trustServerCertificate=true;",
    "connection.username": "sa",
    "connection.password": "YourStrong@Password1",
    "auto.create": "true",
    "auto.evolve": "true",
    "insert.mode": "upsert",
    "delete.enabled": "true",
    "quote.identifiers": "false",
    "primary.key.mode": "record_key",
    "pk.mode": "record_key",
    "primary.key.fields": "Id",
    "pk.fields": "Id",
    "table.name.format": "${topic}",
    //"collection.name.format": "${topic}",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "true",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "true",
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "errors.deadletterqueue.context.headers.enable": "true",
    "errors.deadletterqueue.topic.name": "eticaret.debezium.deadletterqueue",
    "errors.deadletterqueue.topic.replication.factor": "1",
    "transforms": "ExtractAfter,route1",
    "transforms.ExtractAfter.type": "org.apache.kafka.connect.transforms.ExtractField$Value",
    "transforms.ExtractAfter.field": "after",
    "transforms.route1.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route1.regex": "^mssql_src\\.eticaret\\.dbo\\.(.*)$",
    "transforms.route1.replacement": "eticaret_dst.dbo.$1"
  }
}'
```
Başarılı olursa,
Kafka’daki mssql_src.dbo.Product topic’inden gelen veriler eticaret_dst veritabanında otomatik olarak Product tablosuna yazılır.
Order ve Order_Detail için de aynı şekilde işler.
Tablolar otomatik olarak oluşur (veya senkronize edilir).

Sonraki Kontroller

Kafka UI (http://localhost:8080) üzerinden topic’lerde veri var mı kontrol et
eticaret_dst MSSQL veritabanına bağlanarak tabloların ve kayıtların oluşup oluşmadığını gör
```
Connector işlemleri

POST http://localhost:8083/connectors/{connector_name}/restart
DELETE http://localhost:8083/connectors/{connector_name}
GET http://localhost:8083/connectors/{connector_name}/status

GET http://localhost:8083/
GET http://localhost:8083/connector-plugins
GET http://localhost:8083/connectors/{connector_name}
```