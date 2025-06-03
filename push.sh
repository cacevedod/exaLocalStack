export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws events put-events \
    --entries '[{"Source": "mi.aplicacion", "DetailType": "MiTipoDeEvento", "Detail": "{\"order_id\": \"12345678\", \"status\": \"new\", \"timestamp\": \"2025-05-27T12:00:00Z\"}", "EventBusName": "MiEventBusPersonalizado"}]'