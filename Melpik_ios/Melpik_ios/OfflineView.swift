//
//  OfflineView.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI

// MARK: - Offline View
struct OfflineView: View {
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("오프라인 모드")
                .font(.custom("NanumSquareB", size: 20))
                .foregroundColor(.primary)
            
            Text("인터넷 연결을 확인하고 다시 시도해주세요.")
                .font(.custom("NanumSquareR", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: retryAction) {
                Text("연결 확인")
                    .font(.custom("NanumSquareB", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#F6AE24"))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    OfflineView {
        print("Retry action triggered")
    }
} 