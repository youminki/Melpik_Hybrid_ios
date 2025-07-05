//
//  CardAddView.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI

struct CardAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onCardAdded: (Bool, String?) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 카드 번호 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("카드 번호")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("1234 5678 9012 3456", text: $cardNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: cardNumber) { oldValue, newValue in
                            cardNumber = formatCardNumber(newValue)
                        }
                }
                
                // 만료일 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("만료일")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("MM/YY", text: $expiryDate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: expiryDate) { oldValue, newValue in
                            expiryDate = formatExpiryDate(newValue)
                        }
                }
                
                // CVV 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("CVV")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("123", text: $cvv)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: cvv) { oldValue, newValue in
                            if newValue.count > 3 {
                                cvv = String(newValue.prefix(3))
                            }
                        }
                }
                
                // 카드 소유자명 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("카드 소유자명")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("홍길동", text: $cardholderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.words)
                }
                
                Spacer()
                
                // 카드 추가 버튼
                Button(action: addCard) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isLoading ? "처리 중..." : "카드 추가")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isLoading)
                
                // 보안 안내
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                        Text("보안 연결")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text("카드 정보는 암호화되어 안전하게 저장됩니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("카드 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
        .alert("알림", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !cardNumber.replacingOccurrences(of: " ", with: "").isEmpty &&
               !expiryDate.isEmpty &&
               !cvv.isEmpty &&
               !cardholderName.isEmpty &&
               cardNumber.replacingOccurrences(of: " ", with: "").count >= 13
    }
    
    // MARK: - Private Methods
    private func formatCardNumber(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: " ", with: "")
        let formatted = cleaned.enumerated().map { index, char in
            if index > 0 && index % 4 == 0 {
                return " \(char)"
            }
            return String(char)
        }.joined()
        
        return String(formatted.prefix(19)) // 16자리 + 3개 공백
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: "/", with: "")
        if cleaned.count >= 2 {
            let month = String(cleaned.prefix(2))
            let year = String(cleaned.dropFirst(2).prefix(2))
            return "\(month)/\(year)"
        }
        return cleaned
    }
    
    private func addCard() {
        guard isFormValid else {
            alertMessage = "모든 필드를 올바르게 입력해주세요."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        // 실제 카드 등록 API 호출 (여기서는 시뮬레이션)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            
            // 성공 시뮬레이션 (실제로는 API 응답에 따라 처리)
            let success = true
            let errorMessage: String? = nil
            
            if success {
                onCardAdded(true, nil)
                dismiss()
            } else {
                alertMessage = errorMessage ?? "카드 등록에 실패했습니다."
                showingAlert = true
            }
        }
    }
}

#Preview {
    CardAddView { success, error in
        print("Card added: \(success), error: \(error ?? "none")")
    }
} 