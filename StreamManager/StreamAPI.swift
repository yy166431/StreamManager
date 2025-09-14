import Foundation

struct StreamAPI {
    var baseURL: URL                    // e.g. http://<ip>:8088
    var token: String                   // X-Token

    init(host: String, port: String, token: String) {
        var urlStr = host.trimmingCharacters(in: .whitespaces)
        if !urlStr.lowercased().hasPrefix("http") {
            urlStr = "http://\(urlStr)"
        }
        let p = port.trimmingCharacters(in: .whitespaces)
        if let u = URL(string: "\(urlStr):\(p)") {
            self.baseURL = u
        } else {
            self.baseURL = URL(string: "http://127.0.0.1:8088")!
        }
        self.token = token
    }

    func read() async throws -> String {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/read"))
        req.httpMethod = "GET"
        req.setValue(token, forHTTPHeaderField: "X-Token")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return obj?["content"] as? String ?? ""
    }

    func save(content: String) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent("/api/save"))
        req.httpMethod = "POST"
        req.setValue(token, forHTTPHeaderField: "X-Token")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["content": content]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}

