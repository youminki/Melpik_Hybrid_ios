# Melpik Hybrid iOS App

https://me1pik.com/landing을 연결하는 하이브리드 iOS 앱입니다.

## 기능

- **WKWebView 기반 하이브리드 앱**: 네이티브 iOS 앱에서 웹사이트를 로드
- **네비게이션 컨트롤**: 뒤로가기, 앞으로가기, 새로고침, 홈 버튼
- **로딩 인디케이터**: 페이지 로딩 상태 표시
- **제스처 지원**: 스와이프로 뒤로가기/앞으로가기
- **반응형 디자인**: iPhone과 iPad 모두 지원

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

### WebView

- WKWebView를 SwiftUI에서 사용하기 위한 UIViewRepresentable
- 네비게이션 델리게이트 구현
- 로딩 상태 관리

### WebViewStore

- WKWebView 인스턴스 관리
- 웹뷰 설정 (인라인 미디어 재생 등)

## 라이선스

이 프로젝트는 Melpik 팀을 위해 개발되었습니다.
