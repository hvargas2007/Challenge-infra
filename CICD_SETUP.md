# CI/CD Pipeline Setup for CloudFormation

Este documento describe cómo configurar el pipeline CI/CD para desplegar tu infraestructura CloudFormation usando GitHub Actions.

## Requisitos Previos

1. **Cuenta AWS** con permisos para crear recursos CloudFormation
2. **GitHub Repository** (versión gratuita soportada)
3. **AWS IAM Role** para GitHub Actions con políticas necesarias

## Configuración

### 1. Crear IAM Role para GitHub Actions

Crea un IAM Role con confianza OIDC para GitHub Actions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:TU_GITHUB_USERNAME/TU_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Adjunta las siguientes políticas al role:
- `CloudFormationFullAccess`
- `EC2FullAccess`
- `IAMFullAccess`
- `VPCFullAccess`

### 2. Configurar Secrets y Variables en GitHub

Ve a Settings → Secrets and variables → Actions en tu repositorio:

**Secrets:**
- `AWS_ROLE_ARN`: ARN del IAM Role creado (ej: `arn:aws:iam::123456789:role/GitHubActions-CFN-Role`)

**Variables:**
- `AWS_REGION`: Región AWS (ej: `us-east-1`)
- `STACK_NAME`: Nombre base del stack (ej: `api-infrastructure`)

### 3. Estructura del Pipeline

El pipeline incluye dos workflows:

#### validate.yml - Validación Automática
- **Se ejecuta en:** Pull requests y pushes a `develop`
- **Pasos:**
  - Linting con cfn-lint
  - Análisis de seguridad con cfn-nag
  - Validación de sintaxis AWS
  - Detección de drift (si el stack existe)
  - Estimación de costos

#### deploy.yml - Despliegue
- **Se ejecuta en:** Pushes a `main` o manualmente
- **Ambiente:** production
- **Pasos:**
  - Plan de cambios (change set)
  - Despliegue automático
  - Tests post-despliegue

## Flujo de Trabajo

### Desarrollo Normal

1. Crea una rama feature desde `main`
2. Modifica `cf_template.yml`
3. Crea PR hacia `main` → Se ejecuta validación automática
4. Merge a `main` → Despliega automáticamente a producción

### Despliegue Manual

1. Ve a Actions → Deploy CloudFormation
2. Click "Run workflow"
3. Selecciona:
   - **Action**: deploy, update o delete
4. Click "Run workflow"

## Buenas Prácticas Implementadas

1. **Validación en múltiples niveles**
   - Linting sintáctico
   - Análisis de seguridad
   - Validación AWS nativa

2. **Despliegue simplificado**
   - Un solo ambiente (production)
   - Despliegue automático al push a main

3. **Detección de drift**
   - Alerta si el stack ha sido modificado fuera de GitHub

4. **Estimación de costos**
   - Muestra costos estimados antes del despliegue

5. **Change sets**
   - Previsualiza cambios antes de aplicarlos

6. **Tags automáticos**
   - Environment, ManagedBy, Repository, LastDeployedBy, DeploymentTime

## Troubleshooting

### Error: "No credentials"
- Verifica que `AWS_ROLE_ARN` esté configurado correctamente
- Asegúrate que el trust relationship del IAM Role incluya tu repositorio

### Error: "Stack already exists"
- El pipeline maneja automáticamente stacks existentes
- Usa `update` en lugar de `deploy` para stacks existentes

### Error: "No changes to deploy"
- CloudFormation detectó que no hay cambios
- Es normal si el template no ha cambiado

## Monitoreo

- Los resultados se muestran en el Summary de cada workflow
- Revisa los logs detallados en cada paso
- Stack outputs se muestran al final del despliegue

## Seguridad

- Usa OIDC en lugar de access keys
- Los secrets nunca se exponen en logs
- Ambientes protegidos para producción
- Validación de seguridad con cfn-nag