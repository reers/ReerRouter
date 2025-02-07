import MachO
import Foundation

/// Read consecutive data of same type from Mach-O section.
///
/// - Important: ⚠️⚠️⚠️ All data in the section must be of the same type and stored consecutively.
///              Reading mixed types or non-consecutive data will cause crashes!
///
/// Best Practice:
/// - Each section should contain only ONE type of data
/// - Do NOT mix different types in the same section
/// - Create separate sections for different types
/// Example:
///   __DATA,__type1_section  // only for Type1
///   __DATA,__type2_section  // only for Type2
///
/// For different types in same section, use tuple to wrap them:
///
/// Example:
/// ```swift
/// typealias RegisterInfo = (String, (Int) -> Void)
///
/// @_used
/// @_section("__DATA,__register")
/// let register1: RegisterInfo = ("name1", { print($0) })
/// ```
public enum SectionReader {
    /// Reads an array of consecutive elements of type T from specified Mach-O section
    /// - Parameters:
    ///   - type: Type of elements to read
    ///   - segment: Mach-O segment name, defaults to "__DATA"
    ///   - section: Mach-O section name
    /// - Returns: Array of consecutive elements read from the section
    public static func read<T>(
        _ type: T.Type,
        segment: String = "__DATA",
        section: String
    ) -> [T] {
        let imageCount = _dyld_image_count()
        var infos: [T] = []
        
        // Iterate through all loaded Mach-O images
        for i in 0..<imageCount {
            let imageName = String(cString: _dyld_get_image_name(i))
            guard imageName.hasPrefix(Bundle.main.bundlePath) else { continue }
            guard let header = _dyld_get_image_header(i) else { continue }
            guard header.pointee.magic == MH_MAGIC_64 else { continue }
            
            let machHeader = UnsafeRawPointer(header).assumingMemoryBound(to: mach_header_64.self)
            
            // Get pointer to section data
            var size: UInt = 0
            guard let sectionStart = getsectiondata(
                machHeader,
                segment,
                section,
                &size
            ) else { continue }
            
            // Create buffer pointer to read consecutive elements
            guard let buffer: UnsafeBufferPointer<T> = getInfoBuffer(
                from: UnsafeRawPointer(sectionStart),
                sectionSize: Int(size)
            ) else { continue }
            
            // Append all consecutive elements from buffer
            infos.append(contentsOf: buffer)
        }
        return infos
    }
    
    /// Creates an UnsafeBufferPointer to read consecutive elements from section data
    /// - Parameters:
    ///   - sectionStart: Starting pointer of section data
    ///   - sectionSize: Total size of section data in bytes
    /// - Returns: Buffer pointer configured to read consecutive elements
    private static func getInfoBuffer<InfoType>(
        from sectionStart: UnsafeRawPointer,
        sectionSize: Int
    ) -> UnsafeBufferPointer<InfoType>? {
        guard sectionSize > 0 else { return nil }
        
        // Calculate number of consecutive elements based on type size and stride
        let typeSize = MemoryLayout<InfoType>.size
        let typeStride = MemoryLayout<InfoType>.stride
        let count =
            if sectionSize == typeSize { 1 }
            else { 1 + (sectionSize - typeSize) / typeStride }
        
        // Create buffer pointer to read consecutive elements
        let registerInfoPtr = sectionStart.bindMemory(to: InfoType.self, capacity: count)
        return UnsafeBufferPointer(start: registerInfoPtr, count: count)
    }
}
