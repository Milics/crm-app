import http.server
import os
import socketserver
import sys

PORT = 8080
WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'build', 'web'))

class CRMWebHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def translate_path(self, path):
        clean_path = path.split('?', 1)[0].split('#', 1)[0]
        if clean_path.startswith('/crm-app'):
            clean_path = clean_path[len('/crm-app'):]
            if not clean_path.startswith('/'):
                clean_path = '/' + clean_path

        if clean_path in ('', '/'):
            return os.path.join(WEB_DIR, 'index.html')

        full_path = os.path.abspath(os.path.join(WEB_DIR, clean_path.lstrip('/')))
        if os.path.exists(full_path):
            return full_path

        if not os.path.splitext(clean_path)[1]:
            return os.path.join(WEB_DIR, 'index.html')

        return full_path

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def do_GET(self):
        if self.path == '/':
            self.send_response(302)
            self.send_header('Location', '/crm-app/')
            self.end_headers()
            return
        return super().do_GET()

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(('0.0.0.0', PORT), CRMWebHandler) as httpd:
        print(f"🚀 CRM 本地 Web 测试服务已启动！")
        print(f"💻 本机访问: http://localhost:{PORT}/crm-app/")
        print(f"📱 局域网手机访问: http://172.20.10.3:{PORT}/crm-app/")
        httpd.serve_forever()
