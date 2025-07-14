#!/bin/bash

echo "=== VALIDACIÓN DE TRAEFIK ==="
echo ""

# 1. Verificar que Docker está corriendo
echo "1. Verificando Docker..."
if systemctl is-active --quiet docker; then
    echo "✅ Docker está activo"
else
    echo "❌ Docker NO está activo"
    sudo systemctl status docker
fi
echo ""

# 2. Verificar contenedor de Traefik
echo "2. Verificando contenedor Traefik..."
if sudo docker ps | grep -q traefik; then
    echo "✅ Contenedor Traefik está corriendo"
    sudo docker ps | grep traefik
else
    echo "❌ Contenedor Traefik NO está corriendo"
    echo "Intentando ver todos los contenedores:"
    sudo docker ps -a
fi
echo ""

# 3. Verificar logs de Traefik
echo "3. Últimas líneas de logs de Traefik..."
sudo docker logs traefik --tail 20 2>&1
echo ""

# 4. Verificar puertos
echo "4. Verificando puertos..."
for port in 80 443 8080; do
    if sudo netstat -tlpn | grep -q ":$port"; then
        echo "✅ Puerto $port está escuchando"
        sudo netstat -tlpn | grep ":$port"
    else
        echo "❌ Puerto $port NO está escuchando"
    fi
done
echo ""

# 5. Verificar red Docker
echo "5. Verificando red Docker 'web'..."
if sudo docker network ls | grep -q web; then
    echo "✅ Red 'web' existe"
    echo "Contenedores en la red:"
    sudo docker network inspect web | jq '.[0].Containers'
else
    echo "❌ Red 'web' NO existe"
fi
echo ""

# 6. Test local de endpoints
echo "6. Testing endpoints locales..."
echo "- Test puerto 80:"
curl -I localhost:80 2>/dev/null | head -5

echo "- Test puerto 8080 (dashboard):"
curl -I localhost:8080 2>/dev/null | head -5

echo "- Test API con auth:"
curl -s -u admin:admin localhost:8080/api/overview | jq '.http.routers' 2>/dev/null | head -20
echo ""

# 7. Verificar configuración
echo "7. Verificando configuración de Traefik..."
if [ -f /opt/traefik/traefik.yml ]; then
    echo "✅ Archivo de configuración existe"
    echo "Contenido:"
    cat /opt/traefik/traefik.yml | head -20
else
    echo "❌ Archivo de configuración NO encontrado"
fi
echo ""

# 8. Verificar iptables (firewall)
echo "8. Verificando reglas de firewall..."
sudo iptables -L INPUT -n | grep -E "80|443|8080"
echo ""

# 9. Verificar procesos escuchando
echo "9. Procesos escuchando en puertos web..."
sudo lsof -i :80,443,8080 2>/dev/null
echo ""

# 10. Diagnóstico rápido
echo "=== DIAGNÓSTICO RÁPIDO ==="
if sudo docker ps | grep -q traefik && sudo netstat -tlpn | grep -q ":8080"; then
    echo "✅ Traefik parece estar funcionando correctamente"
    echo ""
    echo "Prueba estos comandos:"
    echo "  curl http://localhost"
    echo "  curl -u admin:admin http://localhost:8080/api/overview"
else
    echo "❌ Hay problemas con Traefik"
    echo ""
    echo "Intenta reiniciar:"
    echo "  cd /opt/traefik"
    echo "  sudo docker-compose down"
    echo "  sudo docker-compose up -d"
    echo "  sudo docker-compose logs -f"
fi