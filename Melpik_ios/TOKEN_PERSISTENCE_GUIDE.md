# iOS 토큰 저장 안정성 가이드

## 📋 개요

이 문서는 iOS 앱에서 토큰이 앱 종료 후에도 안정적으로 저장되도록 구현한 기능들을 설명합니다.

## 🔧 구현된 기능들

### 1. 앱 생명주기 이벤트 처리

```swift
// LoginManager.swift
private func setupAppLifecycleObserver() {
    appLifecycleObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.handleAppWillResignActive()
    }
}
```

**기능:**

- 앱이 비활성화될 때 자동으로 토큰 저장 보장
- 백그라운드로 전환 시 토큰 이중 저장

### 2. 토큰 저장 재시도 로직

```swift
func saveToKeychainWithRetry(key: String, value: String, maxRetries: Int = 3) {
    var retryCount = 0
    var success = false

    while retryCount < maxRetries && !success {
        // Keychain 저장 시도
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            success = true
        } else {
            retryCount += 1
            Thread.sleep(forTimeInterval: 0.1) // 잠시 대기 후 재시도
        }
    }
}
```

**기능:**

- Keychain 저장 실패 시 최대 3회 재시도
- 저장 실패 시 로그 기록

### 3. 토큰 저장 확인 시스템

```swift
func verifyTokenStorage() {
    let accessTokenFromDefaults = userDefaults.string(forKey: "accessToken")
    let accessTokenFromKeychain = loadFromKeychain(key: "accessToken")

    // 토큰 불일치 시 Keychain에서 복원
    if accessTokenFromDefaults != accessTokenFromKeychain {
        if let keychainToken = accessTokenFromKeychain {
            userDefaults.set(keychainToken, forKey: "accessToken")
            userDefaults.synchronize()
        }
    }
}
```

**기능:**

- UserDefaults와 Keychain 간 토큰 일치성 확인
- 불일치 시 자동 복원

### 4. 강제 동기화

```swift
// UserDefaults 강제 동기화
userDefaults.synchronize()

// 토큰 저장 확인
verifyTokenStorage()
```

**기능:**

- UserDefaults 즉시 디스크에 저장
- 토큰 저장 상태 실시간 확인

## 🛡️ 보안 설정

### Info.plist 설정

```xml
<!-- 데이터 보호 설정 -->
<key>NSDataProtectionComplete</key>
<true/>

<!-- 키체인 접근 설정 -->
<key>NSKeychainAccessibility</key>
<string>kSecAttrAccessibleAfterFirstUnlock</string>

<!-- 백그라운드 처리 권한 -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>background-processing</string>
</array>
```

## 📱 앱 생명주기 처리

### ContentViewMain에서의 처리

```swift
.onChange(of: scenePhase) { newPhase in
    handleAppLifecycleChange()
}

private func handleAppLifecycleChange() {
    switch scenePhase {
    case .active:
        // 앱 활성화 시 토큰 저장 상태 확인
        loginManager.verifyTokenStorage()

    case .inactive:
        // 앱 비활성화 시 토큰 저장 보장
        loginManager.ensureTokenPersistence()

    case .background:
        // 백그라운드 진입 시 최종 토큰 저장 확인
        loginManager.ensureTokenPersistence()

    @unknown default:
        break
    }
}
```

## 🔍 디버깅 및 모니터링

### 로그 메시지

```
🔄 App will resign active - ensuring token persistence
✅ Token persistence ensured before app backgrounding
🔍 Token storage verification:
  - UserDefaults accessToken: ✅
  - Keychain accessToken: ✅
⚠️ Keychain save failed for key: accessToken, status: -34018
✅ Keychain save successful for key: accessToken (attempt 2)
```

### 토큰 저장 상태 확인

```swift
// 콘솔에서 확인 가능한 정보
print("[saveLoginState] accessToken:", loadFromKeychain(key: "accessToken") ?? "nil")
print("[saveLoginState] refreshToken:", loadFromKeychain(key: "refreshToken") ?? "nil")
```

## 🚀 성능 최적화

### 1. 비동기 처리

- 토큰 저장 작업을 메인 스레드에서 처리하여 UI 블로킹 방지
- 백그라운드에서 토큰 저장 시도

### 2. 메모리 관리

- 앱 생명주기 관찰자 적절한 해제
- weak 참조로 메모리 누수 방지

### 3. 에러 처리

- 저장 실패 시 재시도 로직
- 실패 로그 기록으로 디버깅 지원

## 📋 체크리스트

### 개발자 확인사항

- [ ] 앱 종료 후 재시작 시 로그인 상태 유지 확인
- [ ] 백그라운드 전환 시 토큰 저장 확인
- [ ] Keychain 저장 실패 시 재시도 동작 확인
- [ ] UserDefaults와 Keychain 간 토큰 일치성 확인
- [ ] 앱 생명주기 이벤트 정상 동작 확인

### 테스트 시나리오

1. **정상 로그인 후 앱 종료**

   - 앱 재시작 시 자동 로그인 확인

2. **백그라운드 전환**

   - 홈 버튼 누르기 → 앱 재실행 시 로그인 상태 확인

3. **강제 종료**

   - 앱 스위처에서 앱 강제 종료 → 재실행 시 로그인 상태 확인

4. **네트워크 불안정 상황**
   - 토큰 저장 중 네트워크 끊김 → 재시도 로직 확인

## 🔧 문제 해결

### 일반적인 문제들

1. **토큰이 저장되지 않는 경우**

   - Keychain 접근 권한 확인
   - Info.plist 설정 확인
   - 디버그 로그 확인

2. **앱 재시작 시 로그인 상태가 사라지는 경우**

   - UserDefaults 동기화 확인
   - Keychain 저장 상태 확인
   - 앱 생명주기 이벤트 처리 확인

3. **토큰 불일치 문제**
   - verifyTokenStorage() 메서드 실행
   - UserDefaults와 Keychain 간 동기화 확인

## 📞 지원

문제가 발생하거나 추가 기능이 필요한 경우, 개발팀에 문의하세요.

---

**최종 업데이트:** 2025년 1월
**버전:** 1.0.3
