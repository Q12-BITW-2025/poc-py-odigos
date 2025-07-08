from flask import Flask
from flask_restx import Api, Resource, fields
import os
import requests

app = Flask(__name__)
api = Api(app, version="1.0", title="Proxy API", doc="/")

# Define the proxy input model
proxy_model = api.model('Proxy', {
    'url': fields.String(required=True, description='Target URL'),
    'verb': fields.String(enum=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'], default='GET'),
    'body': fields.Raw(description='JSON payload'),
})


@api.route('/proxy')
class Proxy(Resource):
    @api.expect(proxy_model, validate=True)
    @api.response(200, 'Success')
    @api.response(500, 'Error')
    def post(self):
        """Forward any JSON request to the given URL"""
        data = api.payload
        target = data['url']
        payload = data.get('body', None)

        try:
            resp = requests.get(target, json=payload)
            try:
                body = resp.json()
            except ValueError:
                body = resp.text
            return {
                       'status_code': resp.status_code,
                       'headers': dict(resp.headers),
                       'body': body
                   }, 200
        except Exception as e:
            api.abort(500, str(e))


@api.route('/dummy')
class Proxy(Resource):
    @api.response(200, 'Success')
    def get(self):
        """Dummy api"""
        return {
            "status": "Ok"
        }


if __name__ == '__main__':
    # Port 8080 to match Kubernetes Service
    app.run(debug=True, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
