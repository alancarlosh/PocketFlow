import Foundation

struct Client: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var company: String
    var salesforceAccountId: String?

    init(
        id: UUID = UUID(),
        name: String,
        company: String,
        salesforceAccountId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.company = company
        self.salesforceAccountId = salesforceAccountId
    }
}
