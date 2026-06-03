# PocketFlow CRM

PocketFlow CRM es un proyecto iOS en SwiftUI para practicar como desarrollador Jr. La app combina finanzas personales con una mini integracion estilo Salesforce: registrar ingresos/gastos, relacionarlos con clientes y preparar datos para sincronizacion.

## Stack inicial

- SwiftUI para la interfaz.
- Swift 6.
- MVVM como arquitectura base.
- Servicios in-memory para aprender antes de conectar persistencia y red.
- Tests unitarios con XCTest.

## Como abrirlo

1. Abre `PocketFlow.xcodeproj` en Xcode.
2. Selecciona el scheme `PocketFlow`.
3. Ejecuta en un simulador iOS.

## Objetivo del MVP

- Ver balance total.
- Listar transacciones.
- Registrar ingresos y gastos.
- Relacionar transacciones con clientes.
- Simular una sincronizacion con Salesforce.

## Roadmap de aprendizaje

1. Fundamentos Swift: structs, enums, protocolos, optionals y colecciones.
2. SwiftUI: vistas, estado, listas, formularios y navegacion.
3. MVVM: separar UI, estado y reglas de negocio.
4. Persistencia: migrar de datos mock a SwiftData o Core Data.
5. Networking: crear un cliente HTTP para Salesforce.
6. OAuth: entender login seguro antes de tocar datos reales.
7. Testing: cubrir calculos, view models y servicios.

## Idea de Salesforce

Para aprender sin credenciales reales, el proyecto empieza con `SalesforceSyncServiceMock`. Despues se puede reemplazar por un servicio real que use:

- OAuth 2.0.
- REST API de Salesforce.
- Objetos como `Account`, `Contact` y un objeto custom para gastos.

Nunca guardes tokens reales en el repo.

