"""Teste de integração local; cria uma conta de teste no banco informado."""
import json
import os
import urllib.request
import uuid

BASE = os.getenv('API_BASE_URL', 'http://localhost:8080/amigosdepatas_server/api/')

def request(path, data=None):
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(BASE + path, data=body, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.load(response)

email = 'teste-' + uuid.uuid4().hex + '@example.com'
account = dict(name='Teste de integração', email=email, phone='11999999999', password='Teste-Postgres-123!')
assert request('auth/register.php', account)['success'] is True
assert request('auth/register.php', account)['success'] is False
login = request('auth/login.php', dict(email=email, password=account['password']))
assert login['success'] is True and login['user']['email'] == email
assert 'password_hash' not in login['user']
assert request('auth/login.php', dict(email=email, password='senha-incorreta'))['success'] is False
for route in ['animals', 'campaigns', 'news']:
    result = request('public/' + route + '.php')
    assert result['success'] is True and isinstance(result['items'], list)
assert request('public/about.php')['item']['org_name']
assert request('public/home.php')['data']['stats']['animals_count'] >= 0
print('OK: cadastro, duplicidade, login e consultas públicas. Conta criada:', email)
