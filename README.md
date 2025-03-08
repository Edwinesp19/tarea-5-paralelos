# Sistema de Notificación por Correo Electrónico con AWS Lambda

## Objetivo
Desarrollar un sistema que utilice AWS Lambda para enviar un correo electrónico cuando se reciba un mensaje en una cola de AWS SQS. Se utilizará AWS SNS para gestionar las suscripciones y AWS CloudWatch para monitorizar el proceso. La infraestructura será definida y aprovisionada mediante Terraform.

## Descripción de la Tarea

### 1. Configuración de Terraform
- Define y aprovisiona los recursos de AWS necesarios utilizando Terraform.
- Configura AWS Lambda, AWS SNS, AWS SQS y las políticas de IAM necesarias.
- Crea un bucket de S3 para almacenar los códigos de las funciones Lambda.

### 2. AWS SNS y SQS
- Configura un tópico de SNS que distribuya mensajes a una cola SQS.
- Configura una cola SQS que reciba mensajes del tópico de SNS y los entregue a una función Lambda.

### 3. AWS Lambda
- Desarrolla una función Lambda en Python que se active con eventos de la cola SQS.
- La función debe leer el mensaje de la cola y, basado en el contenido del mensaje, enviar un correo electrónico utilizando SMTP.

#### Formato del mensaje esperado en la cola SQS:
```json
{
  "to": "correo@ejemplo.com",
  "cc": ["cc1@ejemplo.com", "cc2@ejemplo.com"],
  "bcc": ["bcc1@ejemplo.com", "bcc2@ejemplo.com"],
  "origen": "notificaciones@ejemplo.com",
  "asunto": "Asunto del correo",
  "mensaje": "Cuerpo del correo en formato HTML o texto"
}
```

### 4. AWS CloudWatch
- Configura monitoreo para la función Lambda y la cola SQS.
- Crea alarmas para errores en la función Lambda y para la longitud de la cola SQS.

## Documentación y Despliegue

### Requisitos
- Cuenta de AWS con permisos adecuados.
- Terraform instalado en el sistema.
- Configuración de credenciales de AWS en el entorno.

### Pasos para Desplegar
1. Clonar el repositorio:
   ```sh
   git clone https://github.com/Edwinesp19/tarea-5-paralelos.git
   cd tarea-5-paralelos
   ```
2. Inicializar Terraform:
   ```sh
   terraform init
   ```
3. Aplicar la configuración para desplegar los recursos:
   ```sh
   terraform apply
   ```
4. Configurar credenciales de correo en AWS Secrets Manager o como variables de entorno en Lambda.

## Entregables
- Archivos de configuración de Terraform.
- Código fuente de la función Lambda.
- Documentación del sistema y guías de operación.

## Evaluación
- Correcta implementación y funcionalidad de la infraestructura de AWS.
- Efectividad en el envío de correos electrónicos según los eventos de SQS.
- Configuración adecuada de monitoreo y alertas en CloudWatch.

Este sistema proporciona una experiencia práctica con arquitecturas serverless y la automatización de notificaciones, esenciales en entornos de producción modernos.
