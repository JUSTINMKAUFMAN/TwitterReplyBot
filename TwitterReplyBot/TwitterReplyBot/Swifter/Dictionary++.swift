import Foundation

extension Dictionary {
    func filter(_ predicate: (Element) -> Bool) -> Dictionary {
        var filteredDictionary = Dictionary()
        for element in self where predicate(element) {
            filteredDictionary[element.key] = element.value
        }
        return filteredDictionary
    }

    var queryString: String {
        var parts = [String]()

        for (key, value) in self {
            let query: String = "\(key)=\(value)"
            parts.append(query)
        }

        return parts.joined(separator: "&")
    }

    func urlEncodedQueryString(using encoding: String.Encoding) -> String {
        var parts = [String]()

        for (key, value) in self {
            let keyString = "\(key)".urlEncodedString()
            let valueString = "\(value)".urlEncodedString(keyString == "status")
            let query: String = "\(keyString)=\(valueString)"
            parts.append(query)
        }

        return parts.joined(separator: "&")
    }

    func stringifiedDictionary() -> [String: String] {
        var dict = [String: String]()
        for (key, value) in self {
            dict[String(describing: key)] = String(describing: value)
        }
        return dict
    }
}

infix operator +|

func +| <K, V>(left: [K: V], right: [K: V]) -> [K: V] {
    var map = [K: V]()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}
