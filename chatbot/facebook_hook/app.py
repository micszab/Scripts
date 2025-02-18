# facebook_webhook/app.py
from flask import Flask, request, jsonify
from pymessenger.bot import Bot
import requests

app = Flask(__name__)

# Facebook credentials
ACCESS_TOKEN = 'YOUR_ACCESS_TOKEN'
VERIFY_TOKEN = 'YOUR_VERIFY_TOKEN'
RASA_URL = 'http://localhost:5006/webhooks/rest/webhook'  # Rasa endpoint

bot = Bot(ACCESS_TOKEN)

@app.route("/webhook", methods=['GET', 'POST'])
def receive_message():
    if request.method == 'GET':
        token_sent = request.args.get("hub.verify_token")
        return verify_fb_token(token_sent)
    else:
        output = request.get_json()
        print("Incoming request JSON:", output)
        for event in output['entry']:            
            if 'messaging' in event:
                messaging = event['messaging']
                for message in messaging:
                    if message.get('message'):
                        recipient_id = message['sender']['id']
                        if message['message'].get('text'):
                            response = get_rasa_response(message['message'].get('text'), recipient_id)
                            for r in response:
                                print("Send this message: ", response[0])
                                send_message(recipient_id, response[0])
                return "Message Processed"

def verify_fb_token(token_sent):
    if token_sent == VERIFY_TOKEN:
        return request.args.get("hub.challenge")
    return 'Invalid verification token'

def get_rasa_response(user_message, sender_id):
    try:
        print(f"Sending to Rasa: sender={sender_id}, message='{user_message}'")

        # Send request to Rasa
        response = requests.post(
            RASA_URL,
            json={
                "sender": sender_id,
                "message": user_message
            },
            headers={"Content-Type": "application/json"},
            timeout=30  # Fail fast if Rasa is unreachable
        )

        print(f"Rasa response status: {response.status_code}")
        print(f"Rasa response content: {response.text}")

        response.raise_for_status()  # Trigger exception for 4xx/5xx statuses

        # Extract responses (handle empty or invalid data)
        rasa_messages = response.json()
        if not isinstance(rasa_messages, list):
            raise ValueError(f"Unexpected Rasa response format: {rasa_messages}")

        return [msg.get('text', '') for msg in rasa_messages if msg.get('text')]

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {str(e)}")
    except ValueError as e:
        print(f"JSON decode error: {str(e)}")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")

    return ["Sorry, I'm having trouble connecting. Try again later!"]

def send_message(recipient_id, response):
    if recipient_id == ACCESS_TOKEN:  # Prevent bot from messaging itself
        print("Skipping self-message")
        return
    try:
        bot.send_text_message(recipient_id, response)
        print(f"Message sent to {recipient_id}: {response}")
    except Exception as e:
        print(f"Error sending message: {str(e)}")

if __name__ == "__main__":
    app.run(port=5005)