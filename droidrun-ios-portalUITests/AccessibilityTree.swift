//
//  Accessibi.swift
//  droidrun-ios-portal
//
//  Created by Timo Beckmann on 04.06.25.
//
import XCTest
import Foundation

struct AccessibilityTreeCompressor {
    let memoryAddressRegex = try! NSRegularExpression(pattern: #"0x[0-9a-fA-F]+"#)
    func callAsFunction(_ tree: String) -> String {
        let cleaned = memoryAddressRegex.stringByReplacingMatches(
            in: tree,
            range: NSRange(tree.startIndex..., in: tree),
            withTemplate: ""
        ).replacingOccurrences(of: ", ,", with: ",")

        // Remove low-information "Other" lines
        let keptLines = cleaned
            .components(separatedBy: .newlines)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Only look at nodes that start with "Other,"
                guard trimmed.hasPrefix("Other,") else { return true }

                // Keep if it still shows anything useful
                return trimmed.contains("identifier:")
                    || trimmed.contains("label:")
                    || trimmed.contains("placeholderValue:")
            }

        return keptLines.joined(separator: "\n")
    }
}

struct AccessibilityTreeClickables {
    struct Node: Codable {
        var text: String
        var className: String
        var index: Int
        var bounds: String
        var resourceId: String
        var children: [Node]? = nil
    }

    // Heuristics for interactive classes
    static let interactiveClasses: Set<String> = [
        "Button", "Cell", "TextField", "Switch", "Slider", "CollectionViewCell", "TableViewCell", "Link", "Stepper", "ImageButton", "TabBarButton", "SegmentedControl", "PageIndicator", "Picker", "DisclosureTriangle", "MenuItem", "TextView", "Text", "StaticText"
    ]

    // Extracts clickables from the debugDescription
    func callAsFunction(_ tree: String) -> [Node] {
        let lines = tree.components(separatedBy: .newlines)
        var stack: [(indent: Int, node: Node)] = []
        var result: [Node] = []
        var index = 0

        for line in lines {
            let indent = line.prefix { $0 == " " }.count
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Example line: "Button, label: \"OK\", identifier: okButton, enabled, hittable, {{0, 0}, {100, 44}}"
            let components = trimmed.components(separatedBy: ", ")
            guard let className = components.first else { continue }

            // Heuristic: interactive if class is in set, or has identifier/label and is enabled/hittable
            let isInteractive = AccessibilityTreeClickables.interactiveClasses.contains(className)
                || components.contains(where: { $0.hasPrefix("identifier:") || $0.hasPrefix("label:") })
                && (components.contains("enabled") || components.contains("hittable"))

            if !isInteractive { continue }

            // Extract properties
            let text = (components.first(where: { $0.hasPrefix("label:") })?.dropFirst(6).trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) ?? "")
            let identifier = (components.first(where: { $0.hasPrefix("identifier:") })?.dropFirst(11).trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) ?? "")
            let bounds = (components.last(where: { $0.hasPrefix("{{") && $0.contains("}, {") }) ?? "")
            let node = Node(
                text: text.isEmpty ? className : text,
                className: className,
                index: index,
                bounds: bounds,
                resourceId: identifier
            )
            index += 1

            // Tree structure by indentation
            while let last = stack.last, last.indent >= indent {
                stack.removeLast()
            }
            if let parent = stack.last {
                var parentNode = parent.node
                if parentNode.children == nil { parentNode.children = [] }
                parentNode.children?.append(node)
                stack[stack.count - 1].node = parentNode
            } else {
                result.append(node)
            }
            stack.append((indent, node))
        }
        
        return result
    }
}

extension XCUIApplication {
    static let treeCompressor = AccessibilityTreeCompressor()
    static let treeClickables = AccessibilityTreeClickables()
    func accessibilityTree() -> String {
        Self.treeCompressor(debugDescription)
    }
    func accessibilityClickables() -> [AccessibilityTreeClickables.Node] {
        Self.treeClickables(debugDescription)
    }
}
