# Annika Connector

Add-on mínimo para crear un túnel saliente desde Home Assistant hacia un
servidor remoto mediante el cliente de `rathole` v0.5.0. El túnel apunta al
servicio interno `homeassistant:8123`; no publica puertos ni modifica la
configuración de Home Assistant.

## Instalación

1. Publicá este repositorio en una URL Git accesible por Home Assistant.
2. En Home Assistant, abrí **Ajustes → Complementos → Tienda de complementos**.
3. Abrí el menú de la esquina superior derecha, elegí **Repositorios**, pegá la
   URL del repositorio y guardá.
4. Buscá **Annika Connector** en la tienda e instalalo.

## Configuración y uso

En la pestaña **Configuración** del add-on ingresá:

```yaml
server_address: "example.com:2333"
unit_id: "unit-123"
token: "reemplazar-con-el-token-del-servidor"
log_level: "info"
```

El `unit_id` debe coincidir con el nombre del servicio configurado en el
servidor de `rathole` y solo puede contener letras ASCII, números, guiones y
guiones bajos. El token es obligatorio y debe coincidir con el del servicio
remoto.

Guardá la configuración y seleccioná **Iniciar**. Para comprobar la conexión,
abrí la pestaña **Registro** del add-on. El proceso informa la unidad, el
servidor y el destino, pero nunca imprime el token.

Este repositorio implementa únicamente el cliente. El servidor de `rathole` y
su servicio correspondiente deben existir de antemano.
