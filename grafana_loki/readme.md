
Örnek api requestleri
```
http://localhost:3100/loki/api/v1/query_range?query={CorrelationId="{{correlation_id}}", AppName="OrderApi"}&limit=100

http://localhost:3100/loki/api/v1/query_range?query={CorrelationId="a1c03242-6384-4f17-8dcd-f6125617b255", AppName="ProductApi"}&limit=100
```