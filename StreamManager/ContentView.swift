import SwiftUI

struct ContentView: View {
    @AppStorage("serverHost") private var serverHost = ""     // e.g. 139.155.57.242
    @AppStorage("serverPort") private var serverPort = "8088"
    @AppStorage("rememberToken") private var rememberToken = true

    @State private var token: String = Keychain.get("api_token")
    @State private var text: String = ""
    @State private var busy = false
    @State private var msg: String = ""

    var api: StreamAPI {
        .init(host: serverHost, port: serverPort, token: token)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("服务器") {
                    TextField("服务器 IP 或域名", text: $serverHost)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("端口(默认 8088)", text: $serverPort)
                        .keyboardType(.numberPad)
                    HStack {
                        SecureField("令牌 X-Token", text: $token)
                        Toggle("记住令牌", isOn: $rememberToken)
                            .onChange(of: rememberToken) { on in
                                if on { Keychain.set(token, for: "api_token") }
                            }
                            .toggleStyle(.switch)
                    }
                    Button("测试连接 / 读取") { Task { await read() } }
                        .disabled(busy)
                }

                Section("stream_url.txt") {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 240)
                    HStack {
                        Button("保存") { Task { await save() } }
                            .buttonStyle(.borderedProminent)
                            .disabled(busy || token.isEmpty)
                        Button("刷新") { Task { await read() } }
                            .disabled(busy || token.isEmpty)
                        Button("清空") { text = "" }
                            .tint(.red)
                    }
                    if !msg.isEmpty { Text(msg).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("FLV 服务端管理")
            .task {        // 首次进入自动读一次（若已填 token）
                if rememberToken, token.isEmpty == false, !serverHost.isEmpty { await read() }
            }
            .onChange(of: token) { new in
                if rememberToken { Keychain.set(new, for: "api_token") }
            }
        }
    }

    // MARK: - API
    @MainActor
    private func read() async {
        guard !serverHost.isEmpty, !serverPort.isEmpty, !token.isEmpty else {
            msg = "请先填写服务器 / 端口 / 令牌"; return
        }
        busy = true; defer { busy = false }
        do {
            let s = try await api.read()
            text = s
            msg = "读取成功"
        } catch {
            msg = "读取失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func save() async {
        guard !serverHost.isEmpty, !serverPort.isEmpty, !token.isEmpty else {
            msg = "请先填写服务器 / 端口 / 令牌"; return
        }
        busy = true; defer { busy = false }
        do {
            try await api.save(content: text)
            msg = "保存成功"
        } catch {
            msg = "保存失败：\(error.localizedDescription)"
        }
    }
}

