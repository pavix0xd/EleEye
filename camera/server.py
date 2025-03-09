from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import json
# import warning_lights

# global route mapping
routes = {}

def route(method, path):
    def decorator(func):
        if method not in routes:
            routes[method] = {}
        routes[method][path] = func
        return func
    return decorator

class ServerHandler(BaseHTTPRequestHandler):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        self.handle_request("GET")
    
    def do_POST(self):
        self.handle_request("POST")

    def do_PATCH(self):
        self.handle_request("PATCH")
    
    def do_PUT(self):
        self.handle_request("PUT")
    
    def do_DELETE(self):
        self.handle_request("DELETE")
    
    def do_OPTIONS(self):
        self.handle_request("OPTIONS")
    
    def do_CONNECT(self):
        self.handle_request("CONNECT")
    
    def do_HEAD(self):
        self.handle_request("HEAD")
    
    def do_TRACE(self):
        self.handle_request("TRACE")
    

    def handle_request(self,method):
        parsed_url = urlparse(self.path)
        path = parsed_url.path

        if (method in routes) and (path in routes[method]):
            handler = routes[method][path]
            handler(self)

        else:
            self.send_error(404)

    def get_payload(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        return json.loads(post_data.decode('utf-8'))
    
def run(server_class=HTTPServer, handler_class=ServerHandler, port=8080):
    server_address = ("127.0.0.1", port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting request server on port {port}")
    httpd.serve_forever()


# functions to validate warning light POST json payload
def validate_color(color):

    if not isinstance(color,list) or len(color) != 3:
        return False, "Color must be a list of three integers (RGB)"

    for c in color:

        if not 0 <= c <= 255:
            return False, "Color values must be integers between 0 and 255"
    
    return True, None

def validate_duration(duration):

    if not isinstance(duration, int) or duration <= 0:
        return False, "Duration must be a positive integer"

    elif duration > 20:
        return False, "Duration is too long"

    return True, None

def validate_rate(rate):

    if not isinstance(rate, (int, float)) or rate <= 0:
        return False, "Rate must be a positive integer/float"

    return True, None
              
# routes and methods defined here
@route('POST', '/warning_light')
def warning_light(self):

    try:

        payload = self.get_payload()
        color = payload.get('color', [255,0,0]) # what color to use for the warning light. Default of red
        duration = payload.get('duration', 10) # what duration to flicker the warning light on and off
        rate = payload.get('rate', 1) # the frequency of flickers

        # validating the data recieved
        valid_color, color_error = validate_color(color)
        valid_duration, duration_error = validate_duration(duration)
        valid_rate, rate_error = validate_rate(rate)

        # if invalid data was recieved in the JSON payload, all the errors
        # are accumulated in the response body, and a 400 Bad request is sent
        if not valid_color or not valid_duration or not valid_rate:

            errors = []
            response = {}
            if color_error: errors.append(color_error)
            if duration_error: errors.append(duration_error)
            if rate_error: errors.append(rate_error)

            response = {
                "status" : "error",
                "error" : "Bad Request",
                "message" : errors
            }

            # Send response with errors
            self.send_response(400) # Bad request
            self.send_header('Content-type','application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
            return
        
        # if Valid data was recieved, the warning light function which interacts
        # with the Raspberry Pi Board will be called, with the passed in parameters
        #warning_lights.control_warning_lights(color, duration, rate)
        print(f"Simulating warning lights: color={color}, duration={duration}, rate={rate}")

        response = {
            "status" : "success",
            "message" : "Warning light turned on",
            "received_data" : {
                "color" : color,
                "duration" : duration,
                "rate" : rate
            }
        }

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response).encode('utf-8'))
    
    except Exception as e:

        response = {
            "status" : "error",
            "error" : "Internal Server Error",
            "message" : "An unexpected error occured on the server.",
        }

        self.send_response(500)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response).encode('utf-8'))

if __name__ == "__main__":
    run()