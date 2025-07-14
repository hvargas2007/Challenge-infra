# Implementación con Docker

Esta es la versión Docker de la API REST para el challenge.

## Archivos necesarios

```
docker/
├── Dockerfile
├── docker-compose.yml
├── main.py
├── requirements.txt
└── install_docker.sh
```

## Paso 1: Instalar Docker

```bash
# Dar permisos de ejecución
chmod +x install_docker.sh

# Ejecutar instalación
./install_docker.sh

# Cerrar sesión y volver a entrar
exit
# Reconectar por SSM
```

## Paso 2: Verificar que EFS está montado

```bash
# Debe estar montado en /mnt/efs
df -h | grep efs

# Si no está montado:
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0e812c2a1da1c60d3.efs.us-east-1.amazonaws.com:/ /mnt/efs
```

## Paso 3: Preparar los archivos

```bash
# Crear directorio para el proyecto
mkdir -p ~/docker-api
cd ~/docker-api

# Copiar los archivos:
# - Dockerfile
# - docker-compose.yml
# - main.py
# - requirements.txt
```

## Paso 4: Construir y ejecutar

```bash
# Construir la imagen
docker compose build

# Ejecutar en modo detached
docker compose up -d

# Ver los logs
docker compose logs -f

# Verificar que está corriendo
docker ps
```

## Paso 5: Probar la API

```bash
# Health check
curl http://localhost/health

# Ver documentación
# En tu navegador: http://<IP-SERVER>/docs

# Crear un JSON
curl -X POST http://localhost/json \
  -H "Content-Type: application/json" \
  -d '{"id": "docker-test", "data": {"source": "docker", "message": "Hello from Docker"}}'

# Leer el JSON
curl http://localhost/json/docker-test
```

## Comandos útiles de Docker

```bash
# Ver logs
docker compose logs -f

# Reiniciar
docker compose restart

# Detener
docker compose down

# Ver estado
docker compose ps

# Entrar al contenedor
docker compose exec api bash
```

## Ventajas de usar Docker

1. **Portabilidad**: Mismo ambiente en cualquier servidor
2. **Aislamiento**: No afecta el sistema host
3. **Versionado**: Fácil rollback con tags
4. **Escalabilidad**: Fácil replicar containers
5. **Desarrollo**: Mismo ambiente local y producción

## Comparación con instalación directa

| Aspecto | Docker | Instalación directa |
|---------|--------|-------------------|
| Complejidad inicial | Media | Baja |
| Mantenimiento | Fácil | Manual |
| Recursos | Mayor uso RAM | Menor uso |
| Aislamiento | Total | Ninguno |
| Updates | docker pull | apt/pip manual |

## Troubleshooting

Si algo falla:

```bash
# Ver logs detallados
docker compose logs api

# Verificar que el volumen está montado
docker compose exec api ls -la /mnt/efs/json-storage/

# Reconstruir sin cache
docker compose build --no-cache

# Ver uso de recursos
docker stats
```