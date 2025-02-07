# SectionReader
Read consecutive data of same type from Mach-O section. This is frequently used to read registration information, including but not limited to routing configurations, event handlers, and other registration-based data.

Common use cases:
- Route registration
- Event handler registration
- Module initialization
- Feature registration
- Plugin registration

```swift
@_used
@_section("__DATA,__mysection")
let hello: StaticString = "hello"

@_used
@_section("__DATA,__mysection")
let world: StaticString = "world"

// returns ["hello", "world"]
SectionReader.read(StaticString.self, segment: "__DATA", section: "__mysection")
```

# Important
⚠️⚠️⚠️ All data in the section must be of the same type and stored consecutively.
Reading mixed types or non-consecutive data will cause crashes!