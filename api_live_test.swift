#!/usr/bin/env swift
import Foundation

// ============================================
// LIVE API CONNECTIVITY TEST
// ============================================

print("🚨🚨🚨 LIVE API CONNECTIVITY TEST 🚨🚨🚨\n")
print("Testing against REAL APIs - Money on the line!\n")

let testGroup = DispatchGroup()

// ============================================
// TEST 1: DeepSeek API
// ============================================
print("📡 TEST 1: DeepSeek API Connectivity")
print("=" * 50)

testGroup.enter()
let deepseekEndpoint = "https://api.deepseek.com/v1/chat/completions"
var deepseekRequest = URLRequest(url: URL(string: deepseekEndpoint)!)
deepseekRequest.httpMethod = "POST"
deepseekRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
deepseekRequest.setValue("Bearer YOUR_DEEPSEEK_API_KEY", forHTTPHeaderField: "Authorization")

let deepseekBody: [String: Any] = [
    "model": "deepseek-chat",
    "messages": [
        ["role": "user", "content": "Enhance this prompt: A hero stands on a building"]
    ],
    "max_tokens": 100
]

deepseekRequest.httpBody = try? JSONSerialization.data(withJSONObject: deepseekBody)

URLSession.shared.dataTask(with: deepseekRequest) { data, response, error in
    defer { testGroup.leave() }
    
    if let error = error {
        print("❌ DeepSeek API ERROR: \(error.localizedDescription)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ DeepSeek API: No HTTP response")
        return
    }
    
    print("✅ DeepSeek API Response Status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("📦 DeepSeek Response (first 200 chars):")
        print(String(responseString.prefix(200)))
    }
    
    if httpResponse.statusCode == 200 {
        print("✅✅✅ DeepSeek API IS LIVE AND FUNCTIONAL ✅✅✅")
    } else {
        print("⚠️ DeepSeek API returned status: \(httpResponse.statusCode)")
    }
}.resume()

// ============================================
// TEST 2: Pollo Video API
// ============================================
print("\n📡 TEST 2: Pollo Video API Connectivity")
print("=" * 50)

testGroup.enter()
let polloEndpoint = "https://api.piapi.ai/api/v1/task"
var polloRequest = URLRequest(url: URL(string: polloEndpoint)!)
polloRequest.httpMethod = "POST"
polloRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
polloRequest.setValue("Bearer YOUR_POLLO_API_KEY", forHTTPHeaderField: "x-api-key")

let polloBody: [String: Any] = [
    "model": "pollo-1.5",
    "task_type": "text2video",
    "input": [
        "prompt": "Test video generation"
    ]
]

polloRequest.httpBody = try? JSONSerialization.data(withJSONObject: polloBody)

URLSession.shared.dataTask(with: polloRequest) { data, response, error in
    defer { testGroup.leave() }
    
    if let error = error {
        print("❌ Pollo API ERROR: \(error.localizedDescription)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Pollo API: No HTTP response")
        return
    }
    
    print("✅ Pollo API Response Status: \(httpResponse.statusCode)")
    
    if let data = data, let responseString = String(data: data, encoding: .utf8) {
        print("📦 Pollo Response (first 200 chars):")
        print(String(responseString.prefix(200)))
    }
    
    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
        print("✅✅✅ POLLO VIDEO API IS LIVE AND FUNCTIONAL ✅✅✅")
    } else {
        print("⚠️ Pollo API returned status: \(httpResponse.statusCode)")
    }
}.resume()

// Wait for all tests to complete
testGroup.wait()

print("\n" + "=" * 50)
print("🏁 LIVE API TEST COMPLETE")
print("=" * 50)


