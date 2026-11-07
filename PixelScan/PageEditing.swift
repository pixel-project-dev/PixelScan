import Foundation

struct PageDocument: Equatable {
    var pages: [EditablePage]

    func index(of id: UUID) -> Int? {
        pages.firstIndex { $0.id == id }
    }

    mutating func remove(id: UUID) {
        pages.removeAll { $0.id == id }
    }

    mutating func move(_ id: UUID, to newIndex: Int) {
        guard let current = index(of: id) else { return }
        let bounded = min(max(0, newIndex), pages.count - 1)
        guard current != bounded else { return }
        let page = pages.remove(at: current)
        pages.insert(page, at: bounded)
    }

    mutating func rotate(id: UUID, clockwise: Bool) {
        guard let current = index(of: id) else { return }
        if clockwise {
            pages[current].rotation = (pages[current].rotation + 90) % 360
            pages[current].crop = pages[current].crop?.rotatedClockwise()
        } else {
            pages[current].rotation = (pages[current].rotation + 270) % 360
            pages[current].crop = pages[current].crop?.rotatedCounterClockwise()
        }
        pages[current].deskewDegrees = 0
    }

    mutating func update(_ id: UUID, _ body: (inout EditablePage) -> Void) {
        guard let current = index(of: id) else { return }
        body(&pages[current])
    }
}
