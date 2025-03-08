import os
import json
import smtplib
from email.message import EmailMessage

def lambda_handler(event, context):
    smtp_host = os.environ.get("SMTP_HOST")
    smtp_port = int(os.environ.get("SMTP_PORT", 587))
    smtp_user = os.environ.get("SMTP_USER")
    smtp_pass = os.environ.get("SMTP_PASS")

    for record in event.get('Records', []):
        try:
            if not record.get('body'):
                print("Mensaje vacío recibido, ignorando.")
                continue

            # Parsear el JSON recibido
            body = json.loads(record['body'])
            # Si el mensaje proviene de SNS, el contenido real está en "Message"
            if "Message" in body:
                body = json.loads(body["Message"])
        except json.JSONDecodeError as e:
            print(f"Error al parsear el mensaje: {e}")
            continue

        to_addr = body.get("to")
        cc_addr = body.get("cc")
        bcc_addr = body.get("bcc")
        origen   = body.get("origen")

        if not to_addr:
            print("No se encontró destinatario, ignorando mensaje.")
            continue

        msg = EmailMessage()
        msg['Subject'] = "Correo enviado desde AWS Lambda"
        msg['From']    = origen
        msg['To']      = to_addr
        if cc_addr:
            msg['Cc'] = cc_addr
        if bcc_addr:
            msg['Bcc'] = bcc_addr
        msg.set_content("Este es un correo enviado automáticamente desde AWS Lambda utilizando SMTP.")

        try:
            with smtplib.SMTP(smtp_host, smtp_port) as server:
                server.starttls()
                server.login(smtp_user, smtp_pass)
                server.send_message(msg)
                print(f"Correo enviado a {to_addr}")
        except Exception as e:
            print(f"Error al enviar el correo: {e}")

    return {
        'statusCode': 200,
        'body': json.dumps('Mensajes procesados.')
    }