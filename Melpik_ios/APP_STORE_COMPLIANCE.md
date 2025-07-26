# App Store 심사 거부 해결 방안

## 문제 상황

앱스토어 심사에서 다음 두 가지 항목으로 거부되었습니다:

1. **2.1.0 Performance: App Completeness** - 앱 완성도 문제
2. **5.1.1 Legal: Privacy - Data Collection and Storage** - 개인정보 처리 문제

## 해결 방안

### 1. 2.1.0 Performance: App Completeness 해결

#### 문제점

- 네트워크 오류 시 적절한 처리 없음
- 오프라인 상태에서 앱 기능 부족
- 사용자에게 명확한 피드백 부족

#### 해결책

##### A. 오프라인 기능 추가

```swift
// ContentView.swift에 추가된 오프라인 뷰
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
```

##### B. 에러 핸들링 개선

```swift
// WebView Coordinator에 추가된 에러 처리
private func handleNavigationError(_ error: Error) {
    let nsError = error as NSError

    if nsError.domain == NSURLErrorDomain {
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorCannotConnectToHost:
            // 오프라인 상태로 처리
            parent.onOffline()
        default:
            parent.onError("네트워크 연결에 실패했습니다. 다시 시도해주세요.")
        }
    } else {
        parent.onError("페이지를 불러오는데 실패했습니다. 다시 시도해주세요.")
    }
}
```

##### C. 네트워크 모니터링

```swift
// NetworkMonitor를 통한 실시간 연결 상태 감지
.onReceive(networkMonitor.$isConnected) { isConnected in
    if !isConnected && !isLoading {
        handleOffline()
    } else if isConnected && isOffline {
        retryLoading()
    }
}
```

##### D. 오프라인 상태 처리

- `OfflineView` SwiftUI 컴포넌트 구현
- 네트워크 연결 상태 확인 기능
- 자동 재연결 시도
- 사용자 친화적인 인터페이스

### 2. 5.1.1 Legal: Privacy - Data Collection and Storage 해결

#### 문제점

- 개인정보 처리방침 부재
- 사용자 동의 메커니즘 없음
- 데이터 수집 투명성 부족

#### 해결책

##### A. 개인정보 처리방침 생성

- `PrivacyPolicy.md` 파일 생성
- GDPR 준수 내용 포함
- 데이터 수집 목적 명시
- 보유 기간 및 파기 방법 안내

##### B. PrivacyManager 클래스 구현

```swift
@MainActor
class PrivacyManager: ObservableObject {
    @Published var hasAcceptedPrivacyPolicy = false
    @Published var hasAcceptedDataCollection = false
    @Published var hasAcceptedPushNotifications = false
    @Published var hasAcceptedLocationServices = false

    // 사용자 동의 관리
    func acceptPrivacyPolicy() { ... }
    func acceptDataCollection() { ... }
    func revokeConsent(for type: PrivacyConsentType) { ... }

    // GDPR 준수 기능
    func exportUserData() -> [String: Any]? { ... }
    func deleteUserData() { ... }
}
```

##### C. 개인정보 동의 UI

```swift
struct PrivacyConsentView: View {
    @ObservedObject var privacyManager: PrivacyManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 개인정보 수집 항목 설명
                    // 동의 토글 버튼들
                    // 동의 버튼
                }
            }
        }
    }
}
```

##### D. Info.plist 업데이트

```xml
<!-- 개인정보 처리방침 관련 설정 추가 -->
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
        </array>
    </dict>
</array>
```

##### E. 앱 시작 시 개인정보 동의 확인

```swift
private func setupApp() {
    // 개인정보 처리방침 동의 확인
    if privacyManager.requiresPrivacyConsent() {
        privacyManager.showPrivacyPolicy()
        return
    }

    // 동의 후에만 권한 요청
    if privacyManager.canSendPushNotifications() {
        appState.requestPushNotificationPermission()
    }

    if privacyManager.canUseLocationServices() {
        locationManager.requestLocationPermission()
    }
}
```

## 추가 개선사항

### 1. 사용자 경험 개선

- 로딩 상태 표시 개선
- 에러 메시지 한글화
- 재시도 기능 제공

### 2. 성능 최적화

- 네트워크 요청 최적화
- 캐시 정책 개선
- 메모리 사용량 최적화

### 3. 보안 강화

- 개인정보 암호화 저장
- 안전한 데이터 전송
- 접근 권한 제한

## App Store Connect 설정

### 1. App Privacy 설정

- App Store Connect에서 App Privacy 섹션 업데이트
- 데이터 수집 목적 명시
- 제3자 데이터 공유 여부 설정

### 2. 개인정보 처리방침 URL

- 웹사이트에 개인정보 처리방침 페이지 생성
- App Store Connect에 URL 등록

### 3. 스크린샷 업데이트

- 개인정보 동의 화면 스크린샷 추가
- 오프라인 모드 화면 스크린샷 추가

## 테스트 체크리스트

### 기능 테스트

- [ ] 네트워크 연결 해제 시 오프라인 화면 표시
- [ ] 네트워크 복구 시 자동 재연결
- [ ] 개인정보 동의 화면 표시
- [ ] 동의 거부 시 적절한 처리
- [ ] 데이터 수집 동의 후 권한 요청

### UI/UX 테스트

- [ ] 오프라인 화면 디자인 확인
- [ ] 에러 메시지 가독성 확인
- [ ] 개인정보 동의 화면 사용성 확인
- [ ] 다국어 지원 확인

### 보안 테스트

- [ ] 개인정보 암호화 저장 확인
- [ ] 동의 철회 시 데이터 삭제 확인
- [ ] 권한 요청 시점 확인

## 배포 준비

1. **버전 업데이트**: 1.0.3으로 버전 증가
2. **변경사항 문서화**: 릴리즈 노트 작성
3. **테스트 완료**: 모든 기능 정상 작동 확인
4. **App Store Connect 업데이트**: 개인정보 설정 완료
5. **심사 제출**: 변경사항 명시하여 재제출

이러한 개선사항들을 통해 App Store 가이드라인을 준수하고 사용자 경험을 향상시켜 심사 통과를 기대할 수 있습니다.
