import SwiftUI

// MARK: - Tajweed Parser
// Parses Quran.com tajweed HTML tags into colored SwiftUI Text.
//
// Tajweed annotations: from Quran.com API (text_uthmani_tajweed)
// Color scheme: from islamic-network/alquran-tools (the official source
//   that generates the tajweed data for both AlQuran.cloud and Quran.com)
//   Source: github.com/islamic-network/alquran-tools/blob/master/src/AlQuranCloud/Tools/Parser/Tajweed.php
//
// Parser handles: nested tags, combining marks before '<', stray '>' in data.
// Uses NSRegularExpression on UTF-16 to avoid Swift grapheme cluster issues.
// Tested against all 6,236 verses — zero HTML leaks.

enum TajweedParser {
    
    // MARK: - Color mapping
    // Official colors from islamic-network/alquran-tools Tajweed.php
    // This is the canonical source — they generate the tajweed data itself.
    
    static func colorForRule(_ rule: String, theme: AppTheme) -> Color {
        switch rule {
        // Ghunnah — orange
        case "ghunnah":
            return Color(hex: "FF7E1E")
        
        // Ikhfaa — purple
        case "ikhafa":
            return Color(hex: "9400A8")
        
        // Ikhfaa Shafawi — magenta/pink
        case "ikhafa_shafawi":
            return Color(hex: "D500B7")
        
        // Iqlab — cyan/light blue
        case "iqlab":
            return Color(hex: "26BFFD")
        
        // Idgham with Ghunnah — teal
        case "idgham_ghunnah":
            return Color(hex: "169777")
        
        // Idgham Shafawi — green
        case "idgham_shafawi":
            return Color(hex: "58B800")
        
        // Idgham without Ghunnah — green
        case "idgham_wo_ghunnah":
            return Color(hex: "169200")
        
        // Idgham Mutajanisayn / Mutaqaribayn — gray
        case "idgham_mutajanisayn", "idgham_mutaqaribayn":
            return Color(hex: "A1A1A1")
        
        // Qalqalah — red
        case "qalaqah":
            return Color(hex: "DD0008")
        
        // Madd necessary — deep blue
        case "madda_necessary":
            return Color(hex: "000EBC")
        
        // Madd obligatory — medium blue
        case "madda_obligatory":
            return Color(hex: "2144C1")
        
        // Madd permissible — darker blue
        case "madda_permissible":
            return Color(hex: "4050FF")
        
        // Madd normal — blue
        case "madda_normal":
            return Color(hex: "537FFF")
        
        // Silent, Hamza Wasl, Laam Shamsiyah — gray
        case "slnt", "ham_wasl", "laam_shamsiyah":
            return Color(hex: "AAAAAA")
        
        default:
            return theme.textColor
        }
    }
    
    // MARK: - Segment
    
    struct TajweedSegment {
        let text: String
        let rule: String?
    }
    
    // MARK: - Stack-based parser (handles nesting)
    
    static func parse(_ tajweedText: String) -> [TajweedSegment] {
        let nsText = tajweedText as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        
        guard let tagPattern = try? NSRegularExpression(
            pattern: #"<[^>]*>"#, options: []
        ) else {
            return [TajweedSegment(text: cleanText(tajweedText), rule: nil)]
        }
        
        guard let classPattern = try? NSRegularExpression(
            pattern: #"class=([^\s>]+)"#, options: []
        ) else {
            return [TajweedSegment(text: cleanText(tajweedText), rule: nil)]
        }
        
        let tagMatches = tagPattern.matches(in: tajweedText, range: fullRange)
        
        var segments: [TajweedSegment] = []
        var ruleStack: [String] = []
        var lastEnd = 0
        
        for match in tagMatches {
            let tagRange = match.range
            let tagText = nsText.substring(with: tagRange)
            
            if tagRange.location > lastEnd {
                let plainRange = NSRange(location: lastEnd, length: tagRange.location - lastEnd)
                let plain = nsText.substring(with: plainRange)
                let cleaned = cleanText(plain)
                if !cleaned.isEmpty {
                    let currentRule = ruleStack.last
                    segments.append(TajweedSegment(text: cleaned, rule: currentRule))
                }
            }
            
            if tagText.hasPrefix("</") {
                if !ruleStack.isEmpty {
                    ruleStack.removeLast()
                }
            } else {
                let tagNS = tagText as NSString
                let tagRange2 = NSRange(location: 0, length: tagNS.length)
                if let classMatch = classPattern.firstMatch(in: tagText, range: tagRange2) {
                    let className = tagNS.substring(with: classMatch.range(at: 1))
                    ruleStack.append(className)
                }
            }
            
            lastEnd = tagRange.location + tagRange.length
        }
        
        if lastEnd < nsText.length {
            let remainRange = NSRange(location: lastEnd, length: nsText.length - lastEnd)
            let remaining = nsText.substring(with: remainRange)
            let cleaned = cleanText(remaining)
            if !cleaned.isEmpty {
                let currentRule = ruleStack.last
                segments.append(TajweedSegment(text: cleaned, rule: currentRule))
            }
        }
        
        return segments
    }
    
    // MARK: - Text cleaning
    
    private static func cleanText(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "<", with: "")
        result = result.replacingOccurrences(of: ">", with: "")
        return result
    }
    
    static func stripHTML(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "<", with: "")
        result = result.replacingOccurrences(of: ">", with: "")
        return result
    }
    
    // MARK: - Build colored SwiftUI Text
    
    static func coloredText(
        from tajweedText: String,
        fontSize: CGFloat,
        theme: AppTheme,
        showTajweed: Bool = true
    ) -> Text {
        let segments = parse(tajweedText)
        
        if segments.isEmpty {
            return Text(stripHTML(tajweedText))
                .font(.custom(AppConstants.arabicFontName, size: fontSize, relativeTo: .title))
                .foregroundColor(theme.textColor)
        }
        
        var result = Text("")
        for segment in segments {
            let color: Color
            if !showTajweed || segment.rule == nil {
                color = theme.textColor
            } else if segment.rule == "end" {
                color = theme.textColor.opacity(0.5)
            } else {
                color = colorForRule(segment.rule!, theme: theme)
            }
            
            result = result + Text(segment.text)
                .foregroundColor(color)
        }
        
        return result
            .font(.custom(AppConstants.arabicFontName, size: fontSize, relativeTo: .title))
    }
}
