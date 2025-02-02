//
//  HTTPClient.swift
//  STYLiSH
//
//  Created by WU CHIH WEI on 2019/2/13.
//  Copyright © 2019 WU CHIH WEI. All rights reserved.
//

import Foundation

enum LKHTTPError: Error {
    
    case decodeDataFail
    
    case unauthError
    
    case clientError(Data)
    
    case serverError
    
    case unexpectedError
}

extension LKHTTPError: LocalizedError {
    var errorDescription: String? {
        
        switch self {
        
        case .clientError(let data):
            
            do {
                
                let failureResponse = try JSONDecoder.shared.decode(FailureResponse.self, from: data)
                
                return failureResponse.message
                
            } catch(let error) {
                
                return error.localizedDescription
            }
        
        case .decodeDataFail:
            
            return "資料解譯發生錯誤，請詢問大會人員或稍後再試。"
            
        case .serverError:
            
            return "伺服器發生錯誤，請詢問大會人員或稍後再試。"
            
        default:
            
            return "發生非預期錯誤，請詢問大會人員或稍後再試。"
        }
    }
}

enum LKHTTPMethod: String {
    
    case get = "GET"
    
    case post = "POST"
}

enum LKHTTPHeaderField: String {
    
    case contentType = "Content-Type"
    
    case auth = "Authorization"
}

enum LKHTTPHeaderValue: String {
    
    case json = "application/json"
    
    case formData = "application/x-www-form-urlencoded"
}

protocol LKRequest {
    
    var baseURL: String { get }
    
    var headers: [String: String] { get }
    
    var body: Data? { get }
    
    var method: String { get }
    
    var endPoint: String { get }
    
    var queryString: [String: String] { get }
}

extension LKRequest {
    
    var queryString: [String: String] { return [:] }
    
    func makeRequest() -> URLRequest {
        
        let url = URL(string: baseURL + endPoint + makeQueryPath())!
        
        var request = URLRequest(url: url)
        
        request.allHTTPHeaderFields = headers
        
        request.httpBody = body
        
        request.httpMethod = method
        
        return request
    }
    
    func makeQueryPath() -> String {
        
        var result = String.empty
        
        for (key, value) in queryString {
            
            result += key + "=" + value + "&"
        }
        
        return (result.isEmpty) ? "" : "?" + result
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

class HTTPClient {
    
    static let shared = HTTPClient()
    
    private let decoder = JSONDecoder()
    
    private let encoder = JSONEncoder()
    
    private let session: URLSession = {
        
        let queue = OperationQueue()
        
        queue.maxConcurrentOperationCount = 4
        
        return URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: queue
        )
    }()
    
    private init() { }
    
    func request(
        _ request: LKRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        
        session.dataTask(
            with: request.makeRequest(),
            completionHandler: { (data, response, error) in
                
                guard error == nil else {
                    
                    return completion(Result.failure(error!))
                }
                
                // swiftlint:disable force_cast
                let httpResponse = response as! HTTPURLResponse
                // swiftlint:enable force_cast
                let statusCode = httpResponse.statusCode
                
                switch statusCode {
                
                case 200..<300:
                    
                    completion(Result.success(data!))
                    
                case 401:
                    
                    completion(Result.failure(LKHTTPError.unauthError))
                    
                case 400..<500:
                    
                    completion(Result.failure(LKHTTPError.clientError(data!)))
                    
                case 500..<600:
                    
                    completion(Result.failure(LKHTTPError.serverError))
                    
                default: return
                    
                    completion(Result.failure(LKHTTPError.unexpectedError))
                }
                
            }).resume()
    }
}
