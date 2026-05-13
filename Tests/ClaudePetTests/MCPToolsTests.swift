import XCTest
@testable import ClaudePet

/// Surface-level checks on the MCP tool catalog and JSON-RPC request shape.
/// The runtime stdio loop is integration-tested manually (it requires a live
/// IPC socket to the GUI process); here we just guard the schema contract
/// that Claude Desktop sees.
final class MCPToolsTests: XCTestCase {

    // MARK: - tool catalog

    func testNamesContainsExactlyTenTools() {
        XCTAssertEqual(Tools.names.count, 10)
    }

    func testNamesAreTheExpectedSet() {
        let expected: Set<String> = [
            "pet_status", "pet_say", "pet_meow", "pet_feed", "pet_pet", "pet_play",
            "pet_wave", "pet_sleep", "pet_wake", "pet_emote",
        ]
        XCTAssertEqual(Tools.names, expected)
    }

    func testToolListMatchesNames() {
        let listed = Set(Tools.list.compactMap { $0["name"] as? String })
        XCTAssertEqual(listed.count, 10)
        XCTAssertEqual(listed, Tools.names)
    }

    func testEveryToolHasNonEmptyDescriptionAndSchema() {
        for t in Tools.list {
            let name = (t["name"] as? String) ?? "?"
            XCTAssertNotNil(t["name"], "tool entry missing name")
            let desc = t["description"] as? String
            XCTAssertNotNil(desc, "tool \(name) missing description")
            XCTAssertFalse((desc ?? "").isEmpty, "tool \(name) description empty")
            XCTAssertNotNil(t["inputSchema"], "tool \(name) missing inputSchema")
            let schema = t["inputSchema"] as? [String: Any]
            XCTAssertEqual(schema?["type"] as? String, "object",
                           "tool \(name) schema must be object")
        }
    }

    // MARK: - per-tool schema

    private func tool(named name: String) -> [String: Any]? {
        Tools.list.first { ($0["name"] as? String) == name }
    }

    func testPetSayRequiresText() {
        let t = tool(named: "pet_say")
        XCTAssertNotNil(t)
        let schema = t?["inputSchema"] as? [String: Any]
        let required = schema?["required"] as? [String]
        XCTAssertEqual(required, ["text"])

        let props = schema?["properties"] as? [String: Any]
        XCTAssertNotNil(props?["text"])
        XCTAssertNotNil(props?["duration"])
        XCTAssertNotNil(props?["silent"])
    }

    func testPetMeowTextIsOptional() {
        let t = tool(named: "pet_meow")
        let schema = t?["inputSchema"] as? [String: Any]
        let required = schema?["required"] as? [String]
        XCTAssertNil(required, "pet_meow.text should not be required")
        let props = schema?["properties"] as? [String: Any]
        XCTAssertNotNil(props?["text"])
    }

    func testPetEmoteRequiresKindAndConstrainsValues() {
        let t = tool(named: "pet_emote")
        let schema = t?["inputSchema"] as? [String: Any]
        let required = schema?["required"] as? [String]
        XCTAssertEqual(required, ["kind"])

        let props = schema?["properties"] as? [String: Any]
        let kind = props?["kind"] as? [String: Any]
        let allowed = kind?["enum"] as? [String]
        XCTAssertNotNil(allowed)
        XCTAssertEqual(Set(allowed ?? []),
                       ["heart", "sparkle", "star", "crumb", "dust", "note"])
    }

    func testNoArgToolsHaveEmptyProperties() {
        for name in ["pet_status", "pet_feed", "pet_pet", "pet_play", "pet_wave",
                     "pet_sleep", "pet_wake"] {
            guard let t = tool(named: name) else { continue }
            let schema = t["inputSchema"] as? [String: Any]
            let props = schema?["properties"] as? [String: Any]
            XCTAssertEqual(props?.count ?? 0, 0,
                           "tool \(name) should declare no parameters")
        }
    }

    // MARK: - JSON-RPC request shape

    /// Mirror of the parser MCPServer uses on each line. If MCPServer's parsing
    /// shape changes, this test (which mirrors it) will need to be updated in
    /// lockstep — that's the intent.
    func testParsesWellFormedRequest() throws {
        let line = #"{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}"#
        let data = Data(line.utf8)
        let req = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        XCTAssertEqual(req["method"] as? String, "tools/list")
        XCTAssertNotNil(req["id"])
        XCTAssertNotNil(req["params"] as? [String: Any])
    }

    func testIdentifiesNotificationByMissingId() throws {
        let line = #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#
        let data = Data(line.utf8)
        let req = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        XCTAssertNil(req["id"], "request without id is a notification")
    }

    func testParsesToolsCallParams() throws {
        let line = #"{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"pet_emote","arguments":{"kind":"heart","count":12}}}"#
        let data = Data(line.utf8)
        let req = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let params = req["params"] as? [String: Any]
        XCTAssertEqual(params?["name"] as? String, "pet_emote")
        let args = params?["arguments"] as? [String: Any]
        XCTAssertEqual(args?["kind"] as? String, "heart")
        XCTAssertEqual(args?["count"] as? Int, 12)
    }
}
