#!/bin/bash
set -euo pipefail

NS="devops-portfolio"

echo "===== GENERANDO 50 ERRORES 404 Y 30 INTENTOS 401 ====="

kubectl exec -i -n "$NS" deploy/backend -- python - <<'PY'
import urllib.request
import urllib.error
import json

for i in range(50):
    req = urllib.request.Request(
        f"http://localhost:5000/ruta-inexistente-{i}"
    )
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        print(f"404: {e.code}")

for i in range(30):
    req = urllib.request.Request(
        "http://localhost:5000/login",
        data=json.dumps({
            "username": "admin",
            "password": "incorrecta"
        }).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        print(f"Login {i+1}: HTTP {e.code}")
PY

echo "===== ESPERANDO EVALUACIÓN DE PROMETHEUS ====="
sleep 45

echo "===== ALERTAS ACTIVAS ====="
kubectl exec -n "$NS" deploy/backend -- python -c \
"import urllib.request,json; d=json.load(urllib.request.urlopen('http://prometheus-service:9090/api/v1/alerts')); [print(a['labels'].get('alertname'),a['state']) for a in d['data']['alerts']]"

echo "===== PRUEBA FINALIZADA ====="
