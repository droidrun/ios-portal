//
//  Accessibi.swift
//  droidrun-ios-portal
//
//  Created by Timo Beckmann on 04.06.25.
//
import XCTest

struct AccessibilityTreeCompressor {
    let memoryAddressRegex = try! NSRegularExpression(pattern: #"0x[0-9a-fA-F]+"#)
    func callAsFunction(_ tree: String) -> String {
        let cleaned = memoryAddressRegex.stringByReplacingMatches(
            in: tree,
            range: NSRange(tree.startIndex..., in: tree),
            withTemplate: ""
        ).replacingOccurrences(of: ", ,", with: ",")

        // Remove low-information “Other” lines
        let keptLines = cleaned
            .components(separatedBy: .newlines)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Only look at nodes that start with “Other,”
                guard trimmed.hasPrefix("Other,") else { return true }

                // Keep if it still shows anything useful
                return trimmed.contains("identifier:")
                    || trimmed.contains("label:")
                    || trimmed.contains("placeholderValue:")
            }

        return keptLines.joined(separator: "\n")
    }
}

extension XCUIApplication {
    static let treeCompressor = AccessibilityTreeCompressor()
    func accessibilityTree() -> String {
        Self.treeCompressor(debugDescription)
    }
}
