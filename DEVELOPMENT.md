# Guia para crecer con PocketFlow CRM

## Convenciones del proyecto

- `Models`: entidades del dominio, como transacciones y clientes.
- `ViewModels`: estado y acciones que usa SwiftUI.
- `Views`: pantallas y componentes visuales.
- `Services`: integraciones, persistencia y reglas externas.
- `App`: punto de entrada de la app.

## Retos sugeridos

### Nivel 1: Swift y SwiftUI

- Agrega una nueva categoria de transaccion.
- Crea un formulario para registrar una transaccion.
- Muestra gastos e ingresos con colores distintos.

### Nivel 2: Arquitectura

- Mueve los datos mock a un repositorio.
- Agrega validaciones para monto, titulo y cliente.
- Escribe tests para el balance mensual.

### Nivel 3: CRM

- Crea una pantalla de detalle de cliente.
- Muestra cuanto dinero se ha relacionado a cada cliente.
- Marca transacciones como sincronizadas o pendientes.

### Nivel 4: Salesforce

- Investiga OAuth 2.0 Authorization Code Flow.
- Crea un `SalesforceAPIClient`.
- Mapea clientes locales a `Account` o `Contact`.
- Mapea gastos a un objeto custom.

## Regla de oro

Primero hazlo funcionar con datos falsos, luego hazlo limpio, despues conectalo a servicios reales.

