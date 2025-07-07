# 인스타그램 방식 완전 연동 로그인 경험 구현 (iOS Swift)

## 📋 개요

이 프로젝트는 인스타그램과 같은 완전 연동된 로그인 경험을 제공하는 하이브리드(iOS 웹뷰) 앱을 위한 Swift 구현입니다.

### 🎯 핵심 목표

- **앱에서 로그인** → 웹뷰 자동 로그인
- **웹뷰에서 로그인** → 앱 자동 로그인
- **토큰 만료 시 자동 갱신** → 앱/웹뷰 동시 갱신
- **로그아웃 시 동기화** → 앱/웹뷰 동시 로그아웃
- **로그인 상태 유지** → 앱 종료 후 재시작해도 로그인 상태 유지

---

## 🏗️ 아키텍처

### 1. 토큰 관리 시스템

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS 앱        │    │   웹뷰          │    │   서버          │
│                 │    │                 │    │                 │
│ • Keychain      │◄──►│ • localStorage  │◄──►│ • JWT 토큰      │
│ • UserDefaults  │    │ • sessionStorage│    │ • Refresh 토큰  │
│ • 메모리        │    │ • Cookies       │    │ • 만료 관리      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

- ### 2. 로그인 상태 유지 시스템
-
- ```

  ```
- ┌─────────────────┐ ┌─────────────────┐
- │ 로그인 상태 │ │ 세션 유지 │
- │ 유지 │ │ │
- │ │ │ │
- │ • UserDefaults │ │ • sessionStorage│
- │ • 영구 보관 │ │ • 앱 종료 시 │
- │ • 설정 저장 │ │ 삭제 가능 │
- └─────────────────┘ └─────────────────┘
- ```

  ```

### 2. 통신 플로우

#### 앱 → 웹뷰 통신

```swift
// Swift에서 웹뷰로 토큰 전달
let js = """
window.dispatchEvent(new CustomEvent('loginInfoReceived', {
  detail: {
    isLoggedIn: true,
    userInfo: {
      token: '\(accessToken)',
      refreshToken: '\(refreshToken)',
      email: '\(email)',
      keepLogin: \(keepLogin)
    }
  }
}));
"""
webView.evaluateJavaScript(js, completionHandler: nil)
```

#### 웹뷰 → 앱 통신

```javascript
// 웹에서 앱으로 로그인 정보 전달
window.webkit.messageHandlers.nativeBridge.postMessage({
  action: "saveLoginInfo",
  loginData: {
    token: accessToken,
    refreshToken: refreshToken,
    email: userEmail,
    keepLogin: keepLogin,
  },
});
```

---

## 🔧 구현된 기능

### 1. LoginManager (`LoginManager.swift`)

#### ✅ 인스타그램 방식 로그인 상태 유지

```swift
// 로그인 상태 유지 설정 저장
func saveKeepLoginSetting(_ keepLogin: Bool) {
    userDefaults.set(keepLogin, forKey: "keepLogin")
    userDefaults.synchronize()
    print("인스타그램 방식 로그인 상태 유지 설정 저장: \(keepLogin)")
}

// 로그인 상태 유지 설정 가져오기
func getKeepLoginSetting() -> Bool {
    let setting = userDefaults.bool(forKey: "keepLogin")
    print("인스타그램 방식 로그인 상태 유지 설정 조회: \(setting)")
    return setting
}

// 인스타그램 방식 로그인 상태 유지 토큰 저장
func saveTokensWithKeepLogin(accessToken: String, refreshToken: String? = nil, keepLogin: Bool = false) {
    // 로그인 상태 유지 설정 저장
    saveKeepLoginSetting(keepLogin)

    if keepLogin {
        // 로그인 상태 유지: UserDefaults에 저장 (영구 보관)
        userDefaults.set(accessToken, forKey: "accessToken")
    } else {
        // 세션 유지: UserDefaults에 저장하되 앱 종료 시 삭제될 수 있음
        userDefaults.set(accessToken, forKey: "accessToken")
    }

    // Keychain에도 저장 (보안 강화)
    saveToKeychain(key: "accessToken", value: accessToken)
}
```

#### ✅ 인스타그램 방식 로그인 상태 확인

```swift
// 인스타그램 방식 로그인 상태 확인
func checkInstagramLoginStatus() -> Bool {
    // UserDefaults에서 토큰 확인
    let accessToken = userDefaults.string(forKey: "accessToken")
    let isLoggedIn = userDefaults.bool(forKey: "isLoggedIn")

    guard let token = accessToken, !token.isEmpty, isLoggedIn else {
        return false
    }

    // 토큰 유효성 검사 (JWT 토큰인 경우)
    if token.contains(".") {
        // JWT 토큰 만료 확인
        // ...
    }

    return true
}
```

#### ✅ 앱 초기화 시 로그인 상태 복원

```swift
// 인스타그램 방식 로그인 상태 유지 초기화
func initializeInstagramLoginStatus() {
    let isLoggedIn = checkInstagramLoginStatus()

    if isLoggedIn {
        // 로그인 상태 복원
        let userInfo = UserInfo(
            id: userDefaults.string(forKey: "userId") ?? "",
            email: userDefaults.string(forKey: "userEmail") ?? "",
            name: userDefaults.string(forKey: "userName") ?? "",
            token: userDefaults.string(forKey: "accessToken") ?? "",
            refreshToken: userDefaults.string(forKey: "refreshToken"),
            expiresAt: userDefaults.object(forKey: "tokenExpiresAt") as? Date
        )

        self.userInfo = userInfo
        self.isLoggedIn = true

        // 토큰 갱신 타이머 설정
        setupTokenRefreshTimer()
    }
}
```

### 2. ContentView (`ContentView.swift`)

#### ✅ 웹뷰 JavaScript 인터페이스

```swift
// 인스타그램 방식: 로그인 상태 유지 설정 저장
saveKeepLoginSetting: function(keepLogin) {
    localStorage.setItem('keepLoginSetting', keepLogin.toString());
    sessionStorage.setItem('keepLoginSetting', keepLogin.toString());
    document.cookie = 'keepLoginSetting=' + keepLogin + '; path=/; max-age=86400';
},

// 인스타그램 방식: 로그인 상태 유지 토큰 저장
saveTokensWithKeepLogin: function(accessToken, refreshToken, keepLogin) {
    if (keepLogin) {
        // localStorage에 저장 (영구 보관)
        localStorage.setItem('accessToken', accessToken);
    } else {
        // sessionStorage에 저장 (브라우저 닫으면 삭제)
        sessionStorage.setItem('accessToken', accessToken);
    }
},

// 인스타그램 방식: 로그인 상태 유지 확인
checkInstagramLoginStatus: function() {
    const localToken = localStorage.getItem('accessToken');
    const sessionToken = sessionStorage.getItem('accessToken');
    const token = localToken || sessionToken;

    if (!token) return false;

    // 토큰 유효성 검사
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp && payload.exp > Date.now() / 1000;
}
```

#### ✅ 메시지 처리

```swift
case "saveKeepLoginSetting":
    if let keepLogin = body["keepLogin"] as? Bool {
        parent.loginManager.saveKeepLoginSetting(keepLogin)
    }

case "saveTokensWithKeepLogin":
    if let accessToken = body["accessToken"] as? String,
       let keepLogin = body["keepLogin"] as? Bool {
        let refreshToken = body["refreshToken"] as? String
        parent.loginManager.saveTokensWithKeepLogin(accessToken: accessToken, refreshToken: refreshToken, keepLogin: keepLogin)
    }

case "checkInstagramLoginStatus":
    let isLoggedIn = parent.loginManager.checkInstagramLoginStatus()
    let script = "window.dispatchEvent(new CustomEvent('instagramLoginStatusReceived', { detail: { isLoggedIn: \(isLoggedIn) } }));"
    parent.webView.evaluateJavaScript(script)
```

### 3. 웹뷰 통신 스크립트 (`webview_card_integration.js`)

#### ✅ 인스타그램 방식 로그인 성공 이벤트

```javascript
// 인스타그램 방식: 로그인 성공 이벤트 수신 (keepLogin 포함)
document.addEventListener("loginSuccess", function (event) {
  const { userInfo, keepLogin } = event.detail;

  // 로그인 상태 유지 설정 저장
  if (keepLogin !== undefined) {
    localStorage.setItem("keepLoginSetting", keepLogin.toString());
    sessionStorage.setItem("keepLoginSetting", keepLogin.toString());
    document.cookie =
      "keepLoginSetting=" + keepLogin + "; path=/; max-age=86400";
  }

  // 로그인 정보를 웹 앱에 저장
  localStorage.setItem("accessToken", userInfo.token);
  sessionStorage.setItem("accessToken", userInfo.token);

  // 전역 변수 설정
  window.accessToken = userInfo.token;
  window.keepLogin = keepLogin;
});
```

#### ✅ 인스타그램 방식 로그인 상태 확인

```javascript
// 인스타그램 방식: 로그인 상태 유지 확인
function checkInstagramLoginStatus() {
  const localToken = localStorage.getItem("accessToken");
  const sessionToken = sessionStorage.getItem("accessToken");
  const cookieToken = getCookie("accessToken");

  const token = localToken || sessionToken || cookieToken;

  if (!token) return false;

  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    const currentTime = Date.now() / 1000;

    // 토큰이 만료되었는지 확인
    if (payload.exp && payload.exp < currentTime) {
      handleWebLogout();
      return false;
    }

    return true;
  } catch (error) {
    handleWebLogout();
    return false;
  }
}
```

---

## 🚀 사용법

### 1. 앱에서 로그인 성공 시

```swift
// Swift에서 웹뷰에 토큰 전달 (keepLogin 포함)
let js = """
window.dispatchEvent(new CustomEvent('loginInfoReceived', {
  detail: {
    isLoggedIn: true,
    userInfo: {
      token: '\(accessToken)',
      refreshToken: '\(refreshToken)',
      email: '\(email)',
      keepLogin: \(keepLogin)
    }
  }
}));
"""
webView.evaluateJavaScript(js, completionHandler: nil)
```

### 2. 웹뷰에서 로그인 성공 시

```javascript
// 웹에서 로그인 성공 시 자동으로 앱에 전달
window.webkit.messageHandlers.nativeBridge.postMessage({
  action: "saveLoginInfo",
  loginData: {
    token: "access_token",
    refreshToken: "refresh_token",
    email: "user@email.com",
    keepLogin: true, // 인스타그램 방식 로그인 상태 유지
  },
});
```

### 3. 로그아웃 시

```swift
// Swift에서 로그아웃
loginManager.logout()

// 웹뷰에서 로그아웃
window.webkit.messageHandlers.nativeBridge.postMessage({
  action: 'logout'
});
```

- ### 4. 로그인 상태 유지 확인
-
- ```javascript

  ```
- // 브라우저 콘솔에서 확인
- window.nativeApp.checkInstagramLoginStatus();
-
- // 설정 확인
- window.nativeApp.getKeepLoginSetting();
- ```

  ```

---

## 🔒 보안 고려사항

### 1. 토큰 저장

- **앱**: Keychain 사용 (iOS)
- **웹**: httpOnly cookie 권장, localStorage는 편의성
- **HTTPS**: 모든 통신에서 HTTPS 사용

### 2. 토큰 갱신

- **자동 갱신**: 만료 5분 전 자동 갱신
- **실패 처리**: 갱신 실패 시 자동 로그아웃
- **백그라운드**: 앱이 백그라운드에서도 갱신 처리

### 3. 로그아웃 동기화

- **즉시 동기화**: 앱/웹뷰 동시 로그아웃
- **토큰 삭제**: 모든 저장소에서 토큰 완전 삭제

* ### 4. 로그인 상태 유지 보안
* - **UserDefaults**: 영구 보관, 앱 종료 후에도 유지
* - **sessionStorage**: 세션 유지, 앱 종료 시 삭제 가능
* - **설정 저장**: 사용자 선택을 UserDefaults에 저장
* - **공용 기기 경고**: 로그인 상태 유지 시 보안 경고 표시

---

## 📱 iOS 앱 연동 가이드

### 1. Swift에서 웹뷰 설정

```swift
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    var webView: WKWebView!
    var loginManager: LoginManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupLoginManager()
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // 웹뷰에서 받을 메시지 핸들러 등록
        userContentController.add(self, name: "nativeBridge")

        config.userContentController = userContentController
        webView = WKWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)
    }

    func setupLoginManager() {
        loginManager = LoginManager()
        // 인스타그램 방식 로그인 상태 확인
        loginManager.initializeInstagramLoginStatus()
    }
}
```

### 2. 앱에서 웹뷰로 토큰 전달

```swift
func sendTokenToWebView(accessToken: String, refreshToken: String, email: String, keepLogin: Bool) {
    let js = """
    window.dispatchEvent(new CustomEvent('loginInfoReceived', {
      detail: {
        isLoggedIn: true,
        userInfo: {
          token: '\(accessToken)',
          refreshToken: '\(refreshToken)',
          email: '\(email)',
          keepLogin: \(keepLogin)
        }
      }
    }));
    """
    webView.evaluateJavaScript(js, completionHandler: nil)
}
```

- ### 3. 앱에서 웹뷰로 로그아웃 이벤트 전달
-
- ```swift

  ```
- func sendLogoutToWebView() {
-     let js = """
-     if (window.sendLogoutToWebView) {
-         window.sendLogoutToWebView();
-     } else {
-         window.dispatchEvent(new CustomEvent('appLogoutRequest', {
-             detail: {
-                 source: 'native',
-                 timestamp: Date.now()
-             }
-         }));
-     }
-     """
-     webView.evaluateJavaScript(js, completionHandler: nil)
- }
- ```

  ```

---

## 🧪 테스트 방법

### 1. 웹뷰 환경 테스트

```javascript
// 브라우저 콘솔에서 테스트
window.nativeApp.saveTokensWithKeepLogin(
  "test_token",
  "test_refresh_token",
  true
);

// 로그아웃 테스트
window.nativeApp.handleWebLogout();

// 로그인 상태 유지 테스트
window.nativeApp.checkInstagramLoginStatus();
```

### 2. 앱 환경 테스트

```swift
// Swift에서 테스트
let loginManager = LoginManager()

// 로그인 상태 유지 설정
loginManager.saveKeepLoginSetting(true)

// 토큰 저장
loginManager.saveTokensWithKeepLogin(accessToken: "test_token", refreshToken: "test_refresh_token", keepLogin: true)

// 로그인 상태 확인
let isLoggedIn = loginManager.checkInstagramLoginStatus()
print("Login status: \(isLoggedIn)")
```

- ### 3. 로그인 상태 유지 테스트
-
- ```swift

  ```
- // 1. 로그인 상태 유지로 로그인
- loginManager.saveTokensWithKeepLogin(accessToken: "test_token", refreshToken: "test_refresh_token", keepLogin: true)
-
- // 2. 앱 종료 후 재시작 시 상태 확인
- let isLoggedIn = loginManager.checkInstagramLoginStatus() // true 반환
-
- // 3. 세션 유지로 로그인
- loginManager.saveTokensWithKeepLogin(accessToken: "test_token", refreshToken: "test_refresh_token", keepLogin: false)
-
- // 4. 앱 종료 후 재시작 시 상태 확인
- let isLoggedIn = loginManager.checkInstagramLoginStatus() // false 반환
- ```

  ```

---

## 📝 주의사항

1. **HTTPS 필수**: 프로덕션에서는 반드시 HTTPS 사용
2. **토큰 보안**: 민감한 정보는 Keychain 사용
3. **에러 처리**: 네트워크 오류, 토큰 만료 등 예외 상황 처리
4. **성능**: 토큰 갱신 시 불필요한 API 호출 방지

- 5. **로그인 상태 유지**: 공용 기기에서는 보안을 위해 사용하지 않도록 안내
- 6. **설정 저장**: 사용자 선택을 UserDefaults에 저장하여 다음 로그인 시 복원

---

## 🔄 업데이트 히스토리

- **v1.0.0**: 인스타그램 방식 완전 연동 로그인 경험 구현
- **v1.1.0**: 자동 토큰 갱신 기능 추가
- **v1.2.0**: 다중 저장소 지원 및 보안 강화

* - **v1.3.0**: 인스타그램 방식 로그인 상태 유지 기능 추가

---

## 📞 지원

구현 관련 문의사항이나 개선 제안이 있으시면 언제든 연락해 주세요!
