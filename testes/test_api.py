"""Integração com banco LOCAL de demonstração; deixa registros de teste."""
import json
import os
import uuid
import urllib.request
import urllib.error
BASE = os.getenv('API_BASE_URL', 'http://localhost:8080/ong_adocao/backend_api')

def call(route, method='GET', data=None, token=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(BASE + '/index.php?route=' + route, method=method,
        headers=headers, data=json.dumps(data).encode() if data is not None else None)
    try:
        response = urllib.request.urlopen(req, timeout=20)
    except urllib.error.HTTPError as e:
        response = e
    with response:
        payload = json.load(response)
        assert response.status == expected, (route, response.status, payload)
    return payload.get('data')

call('/')
call('/admin/dashboard', expected=401)
admin = call('/auth/login', 'POST', {'email':'admin@ong.local',
    'senha':os.getenv('TEST_ADMIN_PASSWORD','Admin@123')})['token']
call('/auth/perfil', token=admin)
name = 'Teste-' + uuid.uuid4().hex[:12]
user = call('/auth/cadastro', 'POST', {'nome':name, 'email':name.lower()+'@example.com',
    'senha':'SenhaTeste123!', 'aceitou_privacidade':True}, expected=201)['token']
call('/admin/dashboard', token=user, expected=403)
animal = call('/admin/animais', 'POST', {'nome':name,'especie':'cao','vacinado':True}, admin, 201)['id']
assert isinstance(animal, int) and animal > 0
assert call('/animais/'+str(animal))['vacinado'] is True
adoption = call('/adocoes', 'POST', {'animal_id':animal,'tipo_moradia':'Casa',
    'motivo_adocao':'Teste de integração PostgreSQL'}, user, 201)['id']
assert isinstance(adoption, int) and adoption > 0
call('/admin/adocoes/'+str(adoption)+'/status', 'PUT', {'status':'concluida'}, admin)
assert call('/animais/'+str(animal))['status'] == 'adotado'
for resource, body in [
    ('campanhas', {'titulo':name,'descricao':'Teste','meta':100}),
    ('noticias', {'titulo':name,'conteudo':'Teste'}),
    ('videos', {'titulo':name,'url':'https://example.com/video'})]:
    obj = call('/admin/'+resource, 'POST', body, admin, 201)
    assert isinstance(obj['id'], int) and obj['id'] > 0
    call('/admin/'+resource+'/'+str(obj['id']), 'PUT', body, admin)
    call('/'+resource)
    call('/admin/'+resource+'/'+str(obj['id']), 'DELETE', token=admin)
call('/admin/animais/'+str(animal), 'DELETE', token=admin)
assert call('/animais/'+str(animal))['status'] == 'indisponivel'
call('/auth/logout', 'POST', token=user)
call('/auth/perfil', token=user, expected=401)
print('OK: sessões, permissões, cadastro, IDs, conteúdos e adoção. Registros:', name)
