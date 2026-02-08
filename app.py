from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "<h1>Homelab Status: Operational</h1><p>Deploy via GitHub Actions successful!</p>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)