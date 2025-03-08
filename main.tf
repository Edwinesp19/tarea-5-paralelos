##########################################
# Provider y Variables
##########################################
provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

##########################################
# Bucket S3 para el código de Lambda
##########################################
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = "mi-lambda-code-bucket-edwin-123456"  
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "lambda_versioning" {
  bucket = aws_s3_bucket.lambda_code_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

##########################################
# SNS: Tópico para notificaciones y alarmas
##########################################
resource "aws_sns_topic" "alarm_topic" {
  name = "cloudwatch_alarm_topic"
}

##########################################
# SQS: Cola que recibe mensajes de SNS
##########################################
resource "aws_sqs_queue" "sqs_queue" {
  name = "mi_sqs_queue"
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "sqs:SendMessage",
        Resource  = aws_sqs_queue.sqs_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.alarm_topic.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn            = aws_sns_topic.alarm_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.sqs_queue.arn
  raw_message_delivery = true
}

##########################################
# IAM: Rol y Políticas para la función Lambda
##########################################
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_execution_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.lambda_code_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.alarm_topic.arn
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = aws_sqs_queue.sqs_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

##########################################
# Lambda: Función para procesar mensajes de SQS y enviar correo
##########################################
resource "aws_lambda_function" "lambda_function" {
  function_name = "ProcessSQSMessages"
  s3_bucket     = aws_s3_bucket.lambda_code_bucket.bucket
  s3_key        = "proyecto/lambda_function.zip"  
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      SMTP_HOST = "smtp.gmail.com"         # Cambia si usas otro servidor SMTP
      SMTP_PORT = "587"
      SMTP_USER = "edwinespinal1999@gmail.com"      # Tu correo para SMTP
      SMTP_PASS = "tu_contraseña"           # Tu contraseña o contraseña de aplicación
    }
  }
}

# Trigger: Lambda se activa con eventos de SQS
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = aws_sqs_queue.sqs_queue.arn
  function_name    = aws_lambda_function.lambda_function.arn
  batch_size       = 1
  enabled          = true
}

##########################################
# CloudWatch: Alarmas para monitoreo
##########################################
# Alarma para errores en Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors_alarm" {
  alarm_name          = "LambdaErrorsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarma si la función Lambda tiene errores."
  dimensions = {
    FunctionName = aws_lambda_function.lambda_function.function_name
  }
  alarm_actions = [aws_sns_topic.alarm_topic.arn]
}

# Alarma para la longitud de la cola SQS
resource "aws_cloudwatch_metric_alarm" "sqs_length_alarm" {
  alarm_name          = "SQSQueueLengthAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarma cuando la cola SQS tiene más de 10 mensajes."
  dimensions = {
    QueueName = aws_sqs_queue.sqs_queue.name
  }
  alarm_actions = [aws_sns_topic.alarm_topic.arn]
}
