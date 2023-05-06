import os
from http.server import HTTPServer, CGIHTTPRequestHandler

# Make sure the server is created at current directory
os.chdir('.')

# Create server object
listening_port=os.environ.get('LISTENING_PORT')

print("Using Environment Variable LISTENING_PORT : " + listening_port)

server_object = HTTPServer(server_address=('0.0.0.0', int(listening_port)), RequestHandlerClass=CGIHTTPRequestHandler)

print("Running server ...")

# Start the web server
server_object.serve_forever()