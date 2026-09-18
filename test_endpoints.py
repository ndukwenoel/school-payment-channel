import urllib.request, json

# Login
login_data = json.dumps({"email": "mary.adebayo1@excelacademylagos.edu.ng", "password": "password123"}).encode()
req = urllib.request.Request('http://127.0.0.1:8000/api/v1/auth/login', data=login_data, method='POST')
req.add_header('Content-Type', 'application/json')
resp = urllib.request.urlopen(req)
token = json.loads(resp.read())['access_token']
print('Login OK, token obtained')

endpoints = [
    '/api/v1/reports/summary',
    '/api/v1/students/',
    '/api/v1/finance/aging-report',
    '/api/v1/finance/exceptions',
    '/api/v1/finance/revenue-report',
    '/api/v1/finance/expected-settlements',
    '/api/v1/invoices/',
    '/api/v1/erp/academic/classrooms',
    '/api/v1/erp/academic/tests',
]

for ep in endpoints:
    try:
        r = urllib.request.Request(f'http://127.0.0.1:8000{ep}')
        r.add_header('Authorization', f'Bearer {token}')
        resp = urllib.request.urlopen(r)
        data = json.loads(resp.read())
        if isinstance(data, list):
            print(f'OK {ep}: {len(data)} items')
        elif isinstance(data, dict):
            print(f'OK {ep}: {list(data.keys())[:5]}')
        else:
            print(f'OK {ep}: {type(data).__name__}')
    except Exception as e:
        print(f'FAIL {ep}: {e}')
