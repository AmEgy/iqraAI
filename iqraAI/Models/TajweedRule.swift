import SwiftUI

// MARK: - Tajweed Rule Types

/// Represents the tajweed rules as returned by the Quran Foundation API
/// in the `text_uthmani_tajweed` field.
enum TajweedRule: String, CaseIterable {
    case hamzaWasl = "ham_wasl"
    case laamShamsiyah = "laam_shamsiyah"
    case maddNormal = "madda_normal"
    case maddPermissible = "madda_permissible"
    case maddObligatory = "madda_obligatory"
    case qalqalah = "qalpieces"
    case ghunnah = "ghunnah"
    case ikhfaaShafawi = "ikhafa_shafawi"
    case ikhfaa = "ikhafa"
    case iqlab = "iqlab"
    case idghamGhunnah = "idghaam_ghunnah"
    case idghamNoGhunnah = "idghaam_no_ghunnah"
    case idghamMutajanisayn = "idghaam_mutajanisayn"
    case idghamMutaqaribayn = "idghaam_mutaqaribayn"
    case idghamShafawi = "idghaam_shafawi"
    case silent = "silent"
    
    /// The color used to highlight this rule in the Quran text
    var color: Color {
        switch self {
        case .hamzaWasl:             return AppConstants.TajweedColor.hamzaWasl
        case .laamShamsiyah:         return AppConstants.TajweedColor.laamShamsiyah
        case .maddNormal:            return AppConstants.TajweedColor.maddPermissible
        case .maddPermissible:       return AppConstants.TajweedColor.maddPermissible
        case .maddObligatory:        return AppConstants.TajweedColor.maddObligatory
        case .qalqalah:              return AppConstants.TajweedColor.qalqalah
        case .ghunnah:               return AppConstants.TajweedColor.ghunnah
        case .ikhfaaShafawi:         return AppConstants.TajweedColor.ikhfaa
        case .ikhfaa:                return AppConstants.TajweedColor.ikhfaa
        case .iqlab:                 return AppConstants.TajweedColor.iqlab
        case .idghamGhunnah:         return AppConstants.TajweedColor.idghamGhunnah
        case .idghamNoGhunnah:       return AppConstants.TajweedColor.idghamNoGhunnah
        case .idghamMutajanisayn:    return AppConstants.TajweedColor.idghamGhunnah
        case .idghamMutaqaribayn:    return AppConstants.TajweedColor.idghamGhunnah
        case .idghamShafawi:         return AppConstants.TajweedColor.idghamGhunnah
        case .silent:                return AppConstants.TajweedColor.silent
        }
    }
    
    var displayName: String {
        switch self {
        case .hamzaWasl:             return "Hamzat ul-Wasl"
        case .laamShamsiyah:         return "Laam Shamsiyah"
        case .maddNormal:            return "Madd (Normal)"
        case .maddPermissible:       return "Madd (Permissible)"
        case .maddObligatory:        return "Madd (Obligatory)"
        case .qalqalah:              return "Qalqalah"
        case .ghunnah:               return "Ghunnah"
        case .ikhfaaShafawi:         return "Ikhfaa Shafawi"
        case .ikhfaa:                return "Ikhfaa"
        case .iqlab:                 return "Iqlab"
        case .idghamGhunnah:         return "Idgham (with Ghunnah)"
        case .idghamNoGhunnah:       return "Idgham (without Ghunnah)"
        case .idghamMutajanisayn:    return "Idgham Mutajanisayn"
        case .idghamMutaqaribayn:    return "Idgham Mutaqaribayn"
        case .idghamShafawi:         return "Idgham Shafawi"
        case .silent:                return "Silent"
        }
    }
}

// MARK: - Tajweed Text Segment

/// A segment of text that may or may not have a tajweed rule applied.
struct TajweedSegment: Identifiable {
    let id = UUID()
    let text: String
    let rule: TajweedRule?
    
    var color: Color {
        rule?.color ?? AppConstants.TajweedColor.normal
    }
}

// MARK: - Tajweed HTML Parser

/// Parses the `text_uthmani_tajweed` HTML-like format from the Quran Foundation API
/// into structured segments for rendering.
///
/// Input format example:
/// `بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ`
///
/// Output: array of TajweedSegment with text and optional rule
enum TajweedHTMLParser {
    
    /// Parse tajweed-annotated text into colored segments
    static func parse(_ tajweedText: String) -> [TajweedSegment] {
        var segments: [TajweedSegment] = []
        var remaining = tajweedText
        
        while !remaining.isEmpty {
            // Look for the next <tajweed> or <span> tag
            if let tagStart = remaining.range(of: "<tajweed class=") ??
                              remaining.range(of: "<span class=") {
                
                // Text before the tag (plain, no rule)
                let plainText = String(remaining[remaining.startIndex..<tagStart.lowerBound])
                if !plainText.isEmpty {
                    segments.append(TajweedSegment(text: plainText, rule: nil))
                }
                
                // Extract the class name
                let afterClass = remaining[tagStart.upperBound...]
                if let classEnd = afterClass.firstIndex(of: ">") {
                    let className = String(afterClass[afterClass.startIndex..<classEnd])
                        .trimmingCharacters(in: .whitespaces)
                    
                    // Find closing tag
                    let afterOpen = remaining[remaining.index(after: classEnd)...]
                    let closingTag = className.contains("end") ? "</span>" : "</tajweed>"
                    
                    if let closeRange = afterOpen.range(of: closingTag) {
                        let innerText = String(afterOpen[afterOpen.startIndex..<closeRange.lowerBound])
                        let rule = TajweedRule(rawValue: className)
                        segments.append(TajweedSegment(text: innerText, rule: rule))
                        remaining = String(afterOpen[closeRange.upperBound...])
                    } else {
                        // Malformed: no closing tag, treat rest as plain
                        segments.append(TajweedSegment(text: String(afterOpen), rule: nil))
                        remaining = ""
                    }
                } else {
                    // Malformed tag, skip
                    remaining = String(remaining[tagStart.upperBound...])
                }
            } else {
                // No more tags — rest is plain text
                segments.append(TajweedSegment(text: remaining, rule: nil))
                remaining = ""
            }
        }
        
        return segments
    }
    
    /// Build an NSAttributedString from tajweed segments for UIKit rendering
    /// (Use this if SwiftUI Text has RTL issues with colored segments)
    static func attributedString(
        from segments: [TajweedSegment],
        fontSize: CGFloat,
        defaultColor: UIColor = .label
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let fontName = AppConstants.arabicFontName
        let font = UIFont(name: fontName, size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize)
        
        for segment in segments {
            let color: UIColor = if let rule = segment.rule {
                UIColor(rule.color)
            } else {
                defaultColor
            }
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
            ]
            result.append(NSAttributedString(string: segment.text, attributes: attrs))
        }
        
        // Set paragraph direction to RTL
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineSpacing = 12
        result.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: result.length)
        )
        
        return result
    }
}
