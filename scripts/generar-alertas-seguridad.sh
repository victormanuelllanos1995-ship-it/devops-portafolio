#!/bin/bash
set -e

NAMESPACE="devops-portfolio"
HOST="devops-portfolio.local"

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')

if [[ -z "$NODE_IP" || -z "$INGRESS_PORT" ]]; then
  echo "ERROR: No se encontró el nodo o el NodePort de Ingress."
  exit 1
fi

URL="http://${NODE_IP}:${INGRESS_PORT}"

echo "Destino: $URL"
echo "Generando 50 solicitudes a rutas administrativas..."

for i in $(seq 1 50); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Host: $HOST" "$URL/admin-admin-$i")
  echo "GET /admin-admin-$i -> $CODE"
done

echo "Generando 30 intentos de autenticación fallidos..."

for i in $(seq 1 30); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST -H "Host: $HOST" \
    -H "Content-Type: application/json" \
    -d '{"user":"admin","pass":"wrong"}' \
    "$URL/api/v1/login")
  echo "POST /api/v1/login -> $CODE"
done

echo "Verificando alertas de Prometheus..."
curl -s "http://${NODE_IP}:30090/alerts"
echo
