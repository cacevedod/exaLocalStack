# main.tf

# -------------------------------------------------------------
# Configuración del proveedor de AWS
# Apunta a LocalStack para desarrollo local
# -------------------------------------------------------------
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    sqs    = "http://localhost:4566"
    events = "http://localhost:4566"
  }
}

# -------------------------------------------------------------
# Recurso: Cola SQS
# -------------------------------------------------------------
resource "aws_sqs_queue" "my_event_queue" {
  name                       = "mi-cola-de-eventos"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 345600 # 4 días
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30
}

# -------------------------------------------------------------
# Recurso: EventBus de EventBridge
# -------------------------------------------------------------
resource "aws_cloudwatch_event_bus" "my_custom_event_bus" {
  name = "MiEventBusPersonalizado"
}

# -------------------------------------------------------------
# Recurso: Regla de EventBridge
# -------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "my_sqs_rule" {
  name           = "MiReglaEventosSQSSchema"
  event_bus_name = aws_cloudwatch_event_bus.my_custom_event_bus.name
  description    = "Envía eventos de mi.aplicacion con MiTipoDeEvento a la cola SQS"

  event_pattern = jsonencode({
    source      = ["mi.aplicacion"],
    detail-type = ["MiTipoDeEvento"]
  })
}

# -------------------------------------------------------------
# Recurso: Target de EventBridge (SQS)
# -------------------------------------------------------------
resource "aws_cloudwatch_event_target" "sqs_target" {
  rule           = aws_cloudwatch_event_rule.my_sqs_rule.name
  event_bus_name = aws_cloudwatch_event_bus.my_custom_event_bus.name
  target_id      = "MiColaDeEventosTarget"
  arn            = aws_sqs_queue.my_event_queue.arn
}

# -------------------------------------------------------------
# Recurso: Política de permisos para la cola SQS
# Permite que EventBridge envíe mensajes a esta cola.
# -------------------------------------------------------------
resource "aws_sqs_queue_policy" "sqs_eventbridge_policy" {
  queue_url = aws_sqs_queue.my_event_queue.url

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "SQS-EventBridge-Policy",
    Statement = [
      {
        Sid    = "AllowEventBridge",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.my_event_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_bus.my_custom_event_bus.arn
          }
        }
      }
    ]
  })
}

# -------------------------------------------------------------
# Salidas (opcional, pero útil)
# -------------------------------------------------------------
output "sqs_queue_url" {
  description = "URL de la cola SQS creada."
  value       = aws_sqs_queue.my_event_queue.url
}

output "event_bus_name" {
  description = "Nombre del EventBus creado."
  value       = aws_cloudwatch_event_bus.my_custom_event_bus.name
}

output "event_rule_name" {
  description = "Nombre de la regla de EventBridge creada."
  value       = aws_cloudwatch_event_rule.my_sqs_rule.name
}
