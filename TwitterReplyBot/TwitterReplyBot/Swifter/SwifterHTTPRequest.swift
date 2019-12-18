//
//  HTTPRequest.swift
//  Swifter
//
//  Copyright (c) 2014 Matt Donnelly.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import CoreFoundation
import Dispatch
import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public enum HTTPMethodType: String {
    case OPTIONS
    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case TRACE
    case CONNECT
}

public class HTTPRequest: NSObject, URLSessionDataDelegate {
    public typealias UploadProgressHandler = (_ bytesWritten: Int, _ totalBytesWritten: Int, _ totalBytesExpectedToWrite: Int) -> Void
    public typealias DownloadProgressHandler = (Data, _ totalBytesReceived: Int, _ totalBytesExpectedToReceive: Int, HTTPURLResponse) -> Void
    public typealias SuccessHandler = (Data, HTTPURLResponse) -> Void
    public typealias FailureHandler = (Error) -> Void

    internal struct DataUpload {
        var data: Data
        var parameterName: String
        var mimeType: String?
        var fileName: String?
    }

    let url: URL
    let HTTPMethod: HTTPMethodType

    var request: URLRequest?
    var dataTask: URLSessionDataTask?

    var headers: [String: String] = [:]
    var parameters: [String: Any]
    var encodeParameters: Bool

    var uploadData: [DataUpload] = []

    var jsonBody: Data?

    var dataEncoding: String.Encoding = .utf8

    var timeoutInterval: TimeInterval = 60

    var HTTPShouldHandleCookies: Bool = false

    var response: HTTPURLResponse!
    var responseData: Data = Data()

    var uploadProgressHandler: UploadProgressHandler?
    var downloadProgressHandler: DownloadProgressHandler?
    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?

    public init(url: URL, method: HTTPMethodType = .GET, parameters: [String: Any] = [:]) {
        self.url = url
        HTTPMethod = method
        self.parameters = parameters
        encodeParameters = false
    }

    public init(request: URLRequest) {
        self.request = request
        url = request.url!
        HTTPMethod = HTTPMethodType(rawValue: request.httpMethod!)!
        parameters = [:]
        encodeParameters = true
    }

    public func start() {
        if request == nil {
            request = URLRequest(url: url)
            request!.httpMethod = HTTPMethod.rawValue
            request!.timeoutInterval = timeoutInterval
            request!.httpShouldHandleCookies = HTTPShouldHandleCookies

            for (key, value) in headers {
                request!.setValue(value, forHTTPHeaderField: key)
            }

            let nonOAuthParameters = parameters.filter { key, _ in !key.hasPrefix("oauth_") }

            if let body = self.jsonBody {
                request!.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request!.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
                request!.httpBody = body
            } else if !uploadData.isEmpty {
                let boundary = "--" + UUID().uuidString

                let contentType = "multipart/form-data; boundary=\(boundary)"
                request!.setValue(contentType, forHTTPHeaderField: "Content-Type")

                var body = Data()
                for dataUpload in uploadData {
                    let multipartData = HTTPRequest.mulipartContent(with: boundary, data: dataUpload.data, fileName: dataUpload.fileName, parameterName: dataUpload.parameterName, mimeType: dataUpload.mimeType)
                    body.append(multipartData)
                }

                for (key, value): (String, Any) in nonOAuthParameters {
                    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                    body.append("\(value)".data(using: .utf8)!)
                }

                body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

                request!.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
                request!.httpBody = body
            } else if !nonOAuthParameters.isEmpty {
                let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding.rawValue))!
                if HTTPMethod == .GET || HTTPMethod == .HEAD || HTTPMethod == .DELETE {
                    let queryString = nonOAuthParameters.urlEncodedQueryString(using: dataEncoding)
                    request!.url = url.append(queryString: queryString)
                    request!.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                } else {
                    var queryString = ""
                    if encodeParameters {
                        queryString = nonOAuthParameters.urlEncodedQueryString(using: dataEncoding)
                        request!.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                    } else {
                        queryString = nonOAuthParameters.queryString
                    }

                    if let data = queryString.data(using: self.dataEncoding) {
                        request!.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
                        request!.httpBody = data
                    }
                }
            }
        }

        DispatchQueue.main.async {
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
            self.dataTask = session.dataTask(with: self.request!)
            self.dataTask?.resume()

            #if os(iOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            #endif
        }
    }

    public func stop() {
        dataTask?.cancel()
    }

    public func add(multipartData data: Data, parameterName: String, mimeType: String?, fileName: String?) {
        let dataUpload = DataUpload(data: data, parameterName: parameterName, mimeType: mimeType, fileName: fileName)
        uploadData.append(dataUpload)
    }

    public func add(body: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted) {
            jsonBody = data
        }
    }

    private class func mulipartContent(with boundary: String, data: Data, fileName: String?, parameterName: String, mimeType mimeTypeOrNil: String?) -> Data {
        let mimeType = mimeTypeOrNil ?? "application/octet-stream"
        let fileNameContentDisposition = fileName != nil ? "filename=\"\(fileName!)\"" : ""
        let contentDisposition = "Content-Disposition: form-data; name=\"\(parameterName)\"; \(fileNameContentDisposition)\r\n"

        var tempData = Data()
        tempData.append("--\(boundary)\r\n".data(using: .utf8)!)
        tempData.append(contentDisposition.data(using: .utf8)!)
        tempData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        tempData.append(data)
        return tempData
    }

    // MARK: - URLSessionDataDelegate

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        #endif

        defer {
            session.finishTasksAndInvalidate()
        }

        if let error = error {
            failureHandler?(error)
            return
        }

        guard response.statusCode >= 400 else {
            successHandler?(responseData, response)
            return
        }
        let responseString = String(data: responseData, encoding: dataEncoding)!
        let errorCode = HTTPRequest.responseErrorCode(for: responseData) ?? 0
        let localizedDescription = HTTPRequest.description(for: response.statusCode, response: responseString)

        let error = SwifterError(message: localizedDescription, kind: .urlResponseError(status: response.statusCode, headers: response.allHeaderFields, errorCode: errorCode))
        failureHandler?(error)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData.append(data)

        let expectedContentLength = Int(response!.expectedContentLength)
        let totalBytesReceived = responseData.count

        guard !data.isEmpty else { return }
        downloadProgressHandler?(data, totalBytesReceived, expectedContentLength, response)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        responseData.count = 0
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        uploadProgressHandler?(Int(bytesSent), Int(totalBytesSent), Int(totalBytesExpectedToSend))
    }

    // MARK: - Error Responses

    class func responseErrorCode(for data: Data) -> Int? {
        guard let code = JSON(data)["errors"].array?.first?["code"].integer else {
            return nil
        }
        return code
    }

    class func description(for status: Int, response string: String) -> String {
        var s = "HTTP Status \(status)"

        let description: String

        // http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
        // https://dev.twitter.com/overview/api/response-codes
        switch status {
        case 400: description = "Bad Request"
        case 401: description = "Unauthorized"
        case 402: description = "Payment Required"
        case 403: description = "Forbidden"
        case 404: description = "Not Found"
        case 405: description = "Method Not Allowed"
        case 406: description = "Not Acceptable"
        case 407: description = "Proxy Authentication Required"
        case 408: description = "Request Timeout"
        case 409: description = "Conflict"
        case 410: description = "Gone"
        case 411: description = "Length Required"
        case 412: description = "Precondition Failed"
        case 413: description = "Payload Too Large"
        case 414: description = "URI Too Long"
        case 415: description = "Unsupported Media Type"
        case 416: description = "Requested Range Not Satisfiable"
        case 417: description = "Expectation Failed"
        case 420: description = "Enhance Your Calm"
        case 422: description = "Unprocessable Entity"
        case 423: description = "Locked"
        case 424: description = "Failed Dependency"
        case 425: description = "Unassigned"
        case 426: description = "Upgrade Required"
        case 427: description = "Unassigned"
        case 428: description = "Precondition Required"
        case 429: description = "Too Many Requests"
        case 430: description = "Unassigned"
        case 431: description = "Request Header Fields Too Large"
        case 432: description = "Unassigned"
        case 500: description = "Internal Server Error"
        case 501: description = "Not Implemented"
        case 502: description = "Bad Gateway"
        case 503: description = "Service Unavailable"
        case 504: description = "Gateway Timeout"
        case 505: description = "HTTP Version Not Supported"
        case 506: description = "Variant Also Negotiates"
        case 507: description = "Insufficient Storage"
        case 508: description = "Loop Detected"
        case 509: description = "Unassigned"
        case 510: description = "Not Extended"
        case 511: description = "Network Authentication Required"
        default: description = ""
        }

        if !description.isEmpty {
            s = s + ": " + description + ", Response: " + string
        }

        return s
    }
}
