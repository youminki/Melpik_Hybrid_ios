# Melpik Hybrid iOS App

멜픽(Melpik) 하이브리드 iOS 애플리케이션입니다. 웹뷰 기반으로 `me1pik.com`을 로드하여 네이티브 iOS 기능과 웹 콘텐츠를 결합한 앱입니다.

## 📱 앱 정보

- **앱 이름**: Melpik
- **버전**: 1.0.2 (Build 3)
- **플랫폼**: iOS 18.0+
- **아키텍처**: Hybrid (WebView + Native)
- **웹뷰 URL**: https://me1pik.com

## 🚀 주요 기능

### 🌐 웹뷰 통합

- `me1pik.com` 웹사이트 로딩
- 네이티브 iOS 기능과 웹 콘텐츠 결합
- 오프라인 상태 처리

### 🔐 인증 및 보안

- 로그인/회원가입 관리
- 키체인 기반 토큰 저장
- 개인정보 처리방침 준수

### 📍 위치 서비스

- 현재 위치 기반 서비스
- 위치 권한 관리

### 🔔 푸시 알림

- 원격 알림 지원
- 백그라운드 알림 처리

### 📸 미디어 기능

- 카메라 접근
- 사진 라이브러리 접근
- 이미지 업로드

### 💳 카드 통합

- 카드 추가 기능
- JavaScript 브리지 통신

### ⚡ 성능 최적화

- 배터리 효율성 최적화
- 메모리 사용량 모니터링
- 캐시 관리

## 🛠 기술 스택

- **언어**: Swift 5.9+
- **UI 프레임워크**: SwiftUI
- **웹뷰**: WKWebView
- **네트워킹**: URLSession, NWPathMonitor
- **저장소**: UserDefaults, Keychain
- **권한 관리**: PrivacyManager
- **성능 모니터링**: PerformanceMonitor

## 📋 App Store 준비사항

### ✅ 완료된 항목

- [x] App Store 심사 준비 완료
- [x] 개인정보 처리방침 준수
- [x] 데모 계정 설정
- [x] 성능 최적화
- [x] 배터리 효율성 개선
- [x] 오프라인 처리 구현

### 🔑 데모 계정

- **사용자명**: `dbalsrl7647@naver.com`
- **비밀번호**: `qwer1234!`

## 📁 프로젝트 구조

```
Melpik_Hybrid_ios/
├── Melpik_ios/
│   ├── Melpik_ios/
│   │   ├── ContentView.swift          # 메인 UI
│   │   ├── Melpik_iosApp.swift        # 앱 진입점
│   │   ├── NetworkMonitor.swift       # 네트워크 모니터링
│   │   ├── PerformanceMonitor.swift   # 성능 모니터링
│   │   ├── PrivacyManager.swift       # 개인정보 관리
│   │   ├── DemoModeManager.swift      # 데모 모드
│   │   ├── LoginManager.swift         # 로그인 관리
│   │   ├── LocationManager.swift      # 위치 서비스
│   │   ├── CacheManager.swift         # 캐시 관리
│   │   ├── AppStateManager.swift      # 앱 상태 관리
│   │   ├── AppSettingsView.swift      # 설정 화면
│   │   ├── CardAddView.swift          # 카드 추가
│   │   ├── ImagePicker.swift          # 이미지 선택
│   │   ├── SafariView.swift           # Safari 뷰
│   │   ├── ShareSheet.swift           # 공유 기능
│   │   ├── UserInfo.swift             # 사용자 정보
│   │   ├── DebugHelper.swift          # 디버그 도구
│   │   ├── Assets.xcassets/           # 앱 리소스
│   │   ├── Fonts/                     # 폰트 파일
│   │   └── webview_card_integration.js # 웹뷰 통합
│   ├── Melpik_ios.xcodeproj/          # Xcode 프로젝트
│   ├── Info.plist                     # 앱 설정
│   ├── README.md                      # 프로젝트 문서
│   ├── APP_STORE_COMPLIANCE.md        # App Store 준수사항
│   ├── APP_STORE_CONNECT_SETUP.md     # App Store Connect 설정
│   ├── APP_STORE_REVIEW_FIXES.md      # 심사 수정사항
│   ├── ENHANCED_FEATURES.md           # 향상된 기능
│   ├── PrivacyPolicy.md               # 개인정보 처리방침
│   └── screenshots/                   # 앱 스크린샷
└── README.md                          # 프로젝트 개요
```

## 🔧 개발 환경

### 요구사항

- Xcode 16.0+
- iOS 18.0+ SDK
- macOS 14.0+

### 설치 및 실행

1. 프로젝트 클론

```bash
git clone https://github.com/your-username/Melpik_Hybrid_ios.git
cd Melpik_Hybrid_ios/Melpik_ios
```

2. Xcode에서 프로젝트 열기

```bash
open Melpik_ios.xcodeproj
```

3. 시뮬레이터에서 실행

```bash
xcodebuild -project Melpik_ios.xcodeproj -scheme Melpik_ios -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 📄 라이선스

이 프로젝트는 비공개 프로젝트입니다.

## 🤝 기여

현재 이 프로젝트는 비공개이며, 기여는 제한적입니다.

## 📞 지원

문제가 발생하거나 질문이 있으시면 이슈를 생성해주세요.

---

**Melpik Hybrid iOS App** - 웹과 네이티브의 완벽한 조화 🌐📱
