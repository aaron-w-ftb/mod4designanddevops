from flask import Flask
import socket

app = Flask(__name__)

@app.route('/')
def home():

    hostname = socket.gethostname()

    return f"""
    <h1>Hello.</h1>
    <p>I'm currently running in container: {hostname}</p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
