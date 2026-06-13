import Foundation

enum SampleData {
    static let clients = [
        Client(name: "Laura Gomez", company: "Northwind Studio", status: .active, salesforceAccountId: "001-DEMO-001"),
        Client(name: "Marco Ruiz", company: "BlueTrail Consulting", status: .prospect)
    ]

    static let transactions = [
        Transaction(
            title: "Pago de consultoria",
            amount: 12000,
            kind: .income,
            category: .sales,
            client: clients[0],
            syncStatus: .pending
        ),
        Transaction(
            title: "Licencia de software",
            amount: 899,
            kind: .expense,
            category: .software,
            client: clients[0],
            syncStatus: .pending
        ),
        Transaction(
            title: "Transporte a reunion",
            amount: 320,
            kind: .expense,
            category: .transport,
            client: clients[1],
            syncStatus: .pending
        )
    ]
}
