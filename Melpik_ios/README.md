# Melpik Hybrid iOS App

https://me1pik.com/landing을 연결하는 하이브리드 iOS 앱입니다.

## 기능

- **WKWebView 기반 하이브리드 앱**: 네이티브 iOS 앱에서 웹사이트를 로드
- **네비게이션 컨트롤**: 뒤로가기, 앞으로가기, 새로고침, 홈 버튼
- **로딩 인디케이터**: 페이지 로딩 상태 표시
- **제스처 지원**: 스와이프로 뒤로가기/앞으로가기
- **반응형 디자인**: iPhone과 iPad 모두 지원
- **오프라인 지원**: 네트워크 오류 시 오프라인 뷰 표시
- **개인정보 보호**: GDPR 준수 개인정보 처리방침 및 동의 시스템
- **에러 핸들링**: 네트워크 오류, 로딩 실패 등에 대한 적절한 처리

## 기술 스택

- **SwiftUI**: UI 프레임워크
- **WKWebView**: 웹뷰 컴포넌트
- **iOS 18.0+**: 최소 지원 버전

## 설정

### Info.plist 설정

앱에서 HTTPS 연결을 허용하기 위해 다음 설정이 자동으로 추가됩니다:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>me1pik.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>1.0</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## 빌드 및 실행

1. Xcode에서 프로젝트를 엽니다
2. 시뮬레이터 또는 실제 기기를 선택합니다
3. `Cmd + R`로 빌드하고 실행합니다

## 배포

### App Store 배포 준비

1. **Bundle Identifier**: `com.melpik.hybrid`
2. **App Name**: `Melpik`
3. **Version**: 1.0
4. **Deployment Target**: iOS 18.0+

### 필요한 설정

- Apple Developer 계정
- App Store Connect에서 앱 등록
- 코드 서명 설정
- 앱 아이콘 및 스크린샷 준비

## 프로젝트 구조

```
Melpik_ios/
├── Melpik_ios/
│   ├── ContentView.swift          # 메인 뷰 (WKWebView 포함)
│   ├── Melpik_iosApp.swift        # 앱 진입점
│   └── Assets.xcassets/           # 앱 아이콘 및 리소스
├── Melpik_iosTests/               # 단위 테스트
└── Melpik_iosUITests/             # UI 테스트
```

## 주요 컴포넌트

### ContentView

- 메인 UI 레이아웃
- 네비게이션 컨트롤 버튼
- 로딩 인디케이터
- 오프라인/에러 상태 처리

### WebView

- WKWebView를 SwiftUI에서 사용하기 위한 UIViewRepresentable
- 네비게이션 델리게이트 구현
- 로딩 상태 관리
- 에러 핸들링 및 오프라인 감지

### WebViewStore

- WKWebView 인스턴스 관리
- 웹뷰 설정 (인라인 미디어 재생 등)

### PrivacyManager

- 개인정보 처리방침 동의 관리
- GDPR 준수 데이터 수집 투명성
- 사용자 동의 상태 관리
- 데이터 내보내기/삭제 기능

### NetworkMonitor

- 네트워크 연결 상태 모니터링
- 오프라인 상태 감지
- 자동 재연결 처리

## 개인정보 보호 및 규정 준수

### GDPR 준수

- 사용자 동의 기반 데이터 수집
- 데이터 수집 목적의 명확한 고지
- 사용자 데이터 내보내기/삭제 권리 보장
- 데이터 보유 기간 명시

### App Store 가이드라인 준수

- 개인정보 처리방침 제공
- 데이터 수집 투명성
- 사용자 동의 메커니즘
- 오프라인 기능 지원

### 개인정보 수집 항목

- **필수**: 이메일, 사용자명, 디바이스 토큰
- **선택**: 위치 정보, 프로필 이미지
- **자동**: 앱 사용 통계, 오류 로그

## 문제 해결

### App Store 심사 거부 해결

1. **2.1.0 Performance: App Completeness**

   - 오프라인 상태 처리 추가
   - 에러 핸들링 개선
   - 네트워크 오류 시 적절한 UI 제공

2. **5.1.1 Legal: Privacy - Data Collection and Storage**
   - 개인정보 처리방침 추가
   - 사용자 동의 시스템 구현
   - 데이터 수집 투명성 확보

## 라이선스

이 프로젝트는 Melpik 팀을 위해 개발되었습니다.

## 주요 기능

### 🔐 로그인 상태 유지

- Keychain을 사용한 안전한 토큰 저장
- 자동 로그인 기능
- 생체 인증 지원 (Face ID, Touch ID)
- 토큰 만료 시 자동 갱신

### 📱 네이티브 기능

- 푸시 알림
- 위치 서비스
- 카메라/갤러리 접근
- 공유 기능
- Safari 연동
- 네트워크 상태 모니터링

## 웹에서 사용하는 방법

### 로그인 관련 JavaScript API

```javascript
// 1. 로그인 정보 저장 (로그인 성공 시)
window.nativeApp.saveLoginInfo({
  id: "user123",
  email: "user@example.com",
  name: "사용자명",
  token: "access_token_here",
  refreshToken: "refresh_token_here", // 선택사항
  expiresAt: "2024-12-31T23:59:59Z", // 선택사항
});

// 2. 저장된 로그인 정보 가져오기
window.nativeApp.getLoginInfo();

// 3. 로그아웃
window.nativeApp.logout();

// 4. 자동 로그인 설정
window.nativeApp.setAutoLogin(true); // 활성화
window.nativeApp.setAutoLogin(false); // 비활성화

// 5. 로그인 정보 수신 이벤트 리스너
window.addEventListener("loginInfoReceived", function (event) {
  const loginInfo = event.detail;
  console.log("로그인 상태:", loginInfo.isLoggedIn);
  console.log("사용자 정보:", loginInfo.userInfo);

  if (loginInfo.isLoggedIn) {
    // 로그인된 상태 처리
    updateUIForLoggedInUser(loginInfo.userInfo);
  } else {
    // 로그아웃된 상태 처리
    updateUIForLoggedOutUser();
  }
});
```

### 로그인 플로우 예시

```javascript
// 로그인 성공 시
async function handleLoginSuccess(loginResponse) {
  // 네이티브 앱에 로그인 정보 저장
  window.nativeApp.saveLoginInfo({
    id: loginResponse.user.id,
    email: loginResponse.user.email,
    name: loginResponse.user.name,
    token: loginResponse.accessToken,
    refreshToken: loginResponse.refreshToken,
    expiresAt: loginResponse.expiresAt,
  });

  // UI 업데이트
  updateUIForLoggedInUser(loginResponse.user);
}

// 앱 시작 시 로그인 상태 확인
document.addEventListener("DOMContentLoaded", function () {
  // 저장된 로그인 정보 요청
  window.nativeApp.getLoginInfo();
});

// 로그아웃 처리
function handleLogout() {
  window.nativeApp.logout();
  updateUIForLoggedOutUser();
}
```

### 기타 네이티브 기능

```javascript
// 푸시 알림 권한 요청
window.nativeApp.requestPushPermission();

// 위치 정보 가져오기
window.nativeApp.getLocation();

// 생체 인증
window.nativeApp.authenticateWithBiometrics();

// 카메라 열기
window.nativeApp.openCamera();

// 갤러리 열기
window.nativeApp.openImagePicker();

// 링크 공유
window.nativeApp.share("https://example.com");

// Safari에서 열기
window.nativeApp.openInSafari("https://example.com");

// 네트워크 상태 확인
window.nativeApp.getNetworkStatus();

// 앱 정보 가져오기
window.nativeApp.getAppInfo();
```

## 보안 기능

- **Keychain**: 민감한 정보(토큰)를 안전하게 저장
- **생체 인증**: Face ID/Touch ID를 통한 추가 보안
- **토큰 만료 관리**: 자동 토큰 갱신 및 만료 처리
- **자동 로그인**: 사용자 선택에 따른 자동 로그인 기능

## 개발 환경

- iOS 15.0+
- SwiftUI
- WebKit
- Xcode 15.0+
