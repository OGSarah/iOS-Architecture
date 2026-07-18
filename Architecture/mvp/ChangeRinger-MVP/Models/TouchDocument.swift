//
//  TouchDocument.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The one Model type that touches the system: the `.touch` document on disk.
///
/// `TouchDocument` owns only the file format. It reads and writes a `Touch` through
/// `contents(forType:)` and `load(fromContents:ofType:)` and does nothing else. The
/// notation parsing it relies on lives in `PlaceNotation`, so the document is a file
/// format and not a place where domain logic hides.
///
/// Everything about the document's lifecycle, opening, autosaving, conflicts, is handled
/// above this class by `DocumentStoring`, which is why the document itself stays this small.
final class TouchDocument: UIDocument {

    /// The composition held by the document. Defaults to an empty Plain Bob Minor touch.
    var touch: Touch

    /// Creates a document for a file URL, seeding an empty Plain Bob Minor touch.
    ///
    /// - Parameter url: The file URL the document reads from and writes to.
    override init(fileURL url: URL) {
        self.touch = Touch(method: .plainBobMinor)
        super.init(fileURL: url)
    }

    /// Encodes the current touch into the data written to disk.
    ///
    /// - Parameter typeName: The document type being saved. Unused: the format is fixed.
    /// - Returns: The encoded touch as `Data`.
    /// - Throws: An error if encoding fails.
    override func contents(forType typeName: String) throws -> Any {
        TouchDocumentFormat.data(from: touch)
    }

    /// Decodes a touch from the data read from disk.
    ///
    /// A brand new document opens with empty contents, in which case the default touch is
    /// kept so the editor always has something ringable to show.
    ///
    /// - Parameters:
    ///   - contents: The file contents, expected to be `Data`.
    ///   - typeName: The document type being loaded. Unused: the format is fixed.
    /// - Throws: ``TouchDocumentFormat/DecodingError`` if the data is present but malformed.
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data, !data.isEmpty else { return }
        touch = try TouchDocumentFormat.touch(from: data)
    }
}

/// The `.touch` file format: a small, line-based text encoding of a `Touch`.
///
/// The format is deliberately plain text so a composition stays readable and diffable.
/// All notation it contains is parsed back through `PlaceNotation`, keeping the single
/// source of parsing truth in one place.
nonisolated enum TouchDocumentFormat {

    /// A failure encountered while decoding a `.touch` file.
    enum DecodingError: Error, Equatable {

        /// A required field was missing from the file.
        case missingField(String)

        /// The method notation in the file could not be parsed.
        case invalidNotation
    }

    /// The format version written at the top of every file.
    private static let header = "CHANGERINGER-TOUCH v1"

    /// Encodes a touch into file data.
    ///
    /// - Parameter touch: The touch to encode.
    /// - Returns: The UTF-8 file contents.
    static func data(from touch: Touch) -> Data {
        var lines = [
            header,
            "name=\(touch.method.name)",
            "stage=\(touch.method.stage.bellCount)",
            "lead=\(PlaceNotation.string(from: touch.method.plainLead))",
            "bob=\(PlaceNotation.string(from: [touch.method.bobLeadEnd]))",
            "single=\(PlaceNotation.string(from: [touch.method.singleLeadEnd]))",
            "maxLeads=\(touch.maxLeads)"
        ]
        for rowIndex in touch.calls.keys.sorted() {
            if let call = touch.calls[rowIndex] {
                lines.append("call=\(rowIndex):\(call.rawValue)")
            }
        }
        return Data((lines.joined(separator: "\n")).utf8)
    }

    /// Decodes a touch from file data.
    ///
    /// - Parameter data: The file contents.
    /// - Returns: The decoded touch.
    /// - Throws: ``DecodingError`` if a field is missing or the notation cannot be parsed.
    static func touch(from data: Data) throws -> Touch {
        let text = String(decoding: data, as: UTF8.self)
        var fields: [String: String] = [:]
        var calls: [Int: Call] = [:]

        for line in text.split(separator: "\n") {
            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = String(line[line.startIndex..<separator])
            let value = String(line[line.index(after: separator)...])
            if key == "call" {
                let parts = value.split(separator: ":")
                if parts.count == 2, let rowIndex = Int(parts[0]), let call = Call(rawValue: String(parts[1])) {
                    calls[rowIndex] = call
                }
            } else {
                fields[key] = value
            }
        }

        func field(_ key: String) throws -> String {
            guard let value = fields[key] else { throw DecodingError.missingField(key) }
            return value
        }

        let name = try field("name")
        let stageValue = try field("stage")
        let leadNotation = try field("lead")
        let bobNotation = try field("bob")
        let singleNotation = try field("single")

        guard
            let bellCount = Int(stageValue),
            let stage = Stage(rawValue: bellCount),
            let lead = try? PlaceNotation.parse(leadNotation),
            let bob = try? PlaceNotation.parse(bobNotation).first,
            let single = try? PlaceNotation.parse(singleNotation).first
        else {
            throw DecodingError.invalidNotation
        }

        let method = Method(
            name: name,
            stage: stage,
            plainLead: lead,
            bobLeadEnd: bob,
            singleLeadEnd: single
        )
        let maxLeads = fields["maxLeads"].flatMap(Int.init)
        return Touch(method: method, calls: calls, maxLeads: maxLeads)
    }
}
