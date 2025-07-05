# 하이브리드 앱 카드 추가 기능 구현 가이드

## 개요

하이브리드 앱(웹뷰)에서 카드 추가 기능을 네이티브로 처리하여 로그인 세션 공유 문제를 해결하는 구현 가이드입니다.

## 문제 상황

- 웹뷰에서 "카드 추가하기" 버튼 클릭 시 카드 추가 페이지로 이동
- 카드 추가 페이지에서 로그인 정보를 불러올 수 없어 카드 등록 불가능
- 하이브리드 앱에서 웹뷰와 네이티브 간 로그인 세션(쿠키, 토큰 등) 공유 문제

## 해결 방안

### 1. 네이티브에서 웹뷰로 로그인 정보 전달

#### iOS (Swift)

```swift
// LoginManager.swift
func sendLoginInfoToWeb(webView: WKWebView) {
    guard let userInfo = userInfo else { return }

    let script = """
    (function() {
        // localStorage에 로그인 정보 저장
        localStorage.setItem('accessToken', '\(userInfo.token)');
        localStorage.setItem('userId', '\(userInfo.id)');
        localStorage.setItem('userEmail', '\(userInfo.email)');
        localStorage.setItem('userName', '\(userInfo.name)');

        // 쿠키에도 토큰 설정
        document.cookie = 'accessToken=\(userInfo.token); path=/; secure; samesite=strict';
        document.cookie = 'userId=\(userInfo.id); path=/; secure; samesite=strict';

        // 로그인 상태 이벤트 발생
        window.dispatchEvent(new CustomEvent('nativeLoginSuccess', {
            detail: {
                userId: '\(userInfo.id)',
                userEmail: '\(userInfo.email)',
                userName: '\(userInfo.name)',
                accessToken: '\(userInfo.token)'
            }
        }));
    })();
    """

    webView.evaluateJavaScript(script)
}
```

#### Android (Kotlin)

```kotlin
// LoginManager.kt
private fun sendLoginInfoToWeb(webView: WebView, accessToken: String, userId: String, userEmail: String, userName: String) {
    val script = """
        (function() {
            localStorage.setItem('accessToken', '$accessToken');
            localStorage.setItem('userId', '$userId');
            localStorage.setItem('userEmail', '$userEmail');
            localStorage.setItem('userName', '$userName');

            document.cookie = 'accessToken=$accessToken; path=/; secure; samesite=strict';
            document.cookie = 'userId=$userId; path=/; secure; samesite=strict';

            window.dispatchEvent(new CustomEvent('nativeLoginSuccess', {
                detail: {
                    userId: '$userId',
                    userEmail: '$userEmail',
                    userName: '$userName',
                    accessToken: '$accessToken'
                }
            }));
        })();
    """.trimIndent()

    webView.evaluateJavascript(script, null)
}
```

### 2. 카드 추가 요청 네이티브 처리

#### iOS (Swift)

```swift
// ContentView.swift - JavaScript 인터페이스
case "addCard":
    parent.loginManager.handleCardAddRequest(webView: parent.webView) { [weak self] success, errorMessage in
        guard let self = self else { return }

        DispatchQueue.main.async {
            if success {
                self.parent.loginManager.notifyCardAddComplete(webView: self.parent.webView, success: true)
                let script = "window.dispatchEvent(new CustomEvent('cardListRefresh'));"
                self.parent.webView.evaluateJavaScript(script)
            } else {
                self.parent.loginManager.notifyCardAddComplete(webView: self.parent.webView, success: false, errorMessage: errorMessage)
            }
        }
    }
```

#### Android (Kotlin)

```kotlin
// MainActivity.kt - JavaScript 인터페이스
@JavascriptInterface
fun addCard() {
    runOnUiThread {
        loginManager.handleCardAddRequest(webView) { success, errorMessage ->
            runOnUiThread {
                if (success) {
                    loginManager.notifyCardAddComplete(webView, true)
                    val script = "window.dispatchEvent(new CustomEvent('cardListRefresh'));"
                    webView.evaluateJavascript(script, null)
                } else {
                    loginManager.notifyCardAddComplete(webView, false, errorMessage)
                }
            }
        }
    }
}
```

### 3. 웹뷰에서 네이티브 호출

#### JavaScript

```javascript
// 카드 추가 버튼 클릭 시
function handleCardAddClick() {
  if (isNativeApp()) {
    // 네이티브 앱에서 카드 추가 화면 표시
    window.nativeApp.addCard();
  } else {
    // 웹 환경에서는 기존 웹 카드 추가 로직 실행
    showWebCardAddForm();
  }
}

// 네이티브 앱 환경 확인
function isNativeApp() {
  return typeof window.nativeApp !== "undefined";
}

// 네이티브에서 카드 추가 완료 이벤트 수신
document.addEventListener("cardAddComplete", function (event) {
  const { success, errorMessage } = event.detail;

  if (success) {
    showSuccessMessage("카드가 성공적으로 추가되었습니다.");
    refreshCardList();
  } else {
    showErrorMessage(errorMessage || "카드 추가에 실패했습니다.");
  }
});

// 카드 목록 새로고침 이벤트 수신
document.addEventListener("cardListRefresh", function () {
  refreshCardList();
});
```

## 구현된 파일들

### iOS

1. **LoginManager.swift** - 로그인 상태 관리 및 웹뷰 통신
2. **ContentView.swift** - 웹뷰 설정 및 JavaScript 인터페이스
3. **CardAddView.swift** - 카드 추가 네이티브 화면
4. **webview_card_integration.js** - 웹뷰 JavaScript 예시

### Android

1. **Android_Card_Integration.kt** - Android 구현 예시

## 사용법

### 1. iOS 앱에서 사용

1. **프로젝트에 파일 추가**

   - `LoginManager.swift` 수정
   - `ContentView.swift` 수정
   - `CardAddView.swift` 추가

2. **웹뷰에서 카드 추가 버튼에 이벤트 추가**

```html
<button class="card-add-button" onclick="handleCardAddClick()">
  카드 추가하기
</button>
```

3. **JavaScript 이벤트 리스너 추가**

```javascript
document.addEventListener("click", function (event) {
  if (event.target.matches(".card-add-button")) {
    event.preventDefault();
    handleCardAddClick();
  }
});
```

### 2. Android 앱에서 사용

1. **MainActivity에 WebView 설정**
2. **LoginManager 클래스 구현**
3. **CardAddActivity 구현**
4. **웹뷰 JavaScript 인터페이스 추가**

## 이벤트 흐름

1. **웹뷰에서 카드 추가 버튼 클릭**
2. **네이티브 앱 환경 확인**
3. **네이티브 카드 추가 화면 표시**
4. **카드 정보 입력 및 등록**
5. **등록 완료 후 웹뷰에 결과 전달**
6. **웹뷰에서 카드 목록 새로고침**

## 보안 고려사항

### iOS

- Keychain을 사용하여 민감한 정보 저장
- UserDefaults는 기본 정보만 저장
- 토큰 만료 시간 확인

### Android

- AndroidKeyStore를 사용하여 민감한 정보 암호화 저장
- SharedPreferences는 기본 정보만 저장
- 토큰 만료 시간 확인

## 디버깅

### 로그 확인

```swift
// iOS
print("sendLoginInfoToWeb called with userInfo: \(userInfo)")
print("handleCardAddRequest called")
```

```kotlin
// Android
println("Login info saved successfully")
println("Card add request received")
```

### 웹뷰 콘솔 확인

```javascript
// 브라우저 개발자 도구에서 확인
console.log("Native login info sent to web");
console.log("Card add complete notification received");
```

## 추가 개선사항

1. **토큰 갱신 로직 구현**
2. **에러 처리 강화**
3. **로딩 상태 표시**
4. **네트워크 상태 확인**
5. **오프라인 모드 지원**

## 문제 해결

### 로그인 정보가 전달되지 않는 경우

1. `LoginManager`의 `sendLoginInfoToWeb` 메서드 호출 확인
2. 웹뷰 로딩 완료 후 호출되는지 확인
3. JavaScript 콘솔에서 에러 확인

### 카드 추가 화면이 표시되지 않는 경우

1. `ContentView`의 `showingCardAddView` 상태 확인
2. `NotificationCenter` 알림 수신 확인
3. `CardAddView` 파일이 프로젝트에 추가되었는지 확인

### 웹뷰에서 이벤트를 받지 못하는 경우

1. JavaScript 인터페이스가 올바르게 등록되었는지 확인
2. 이벤트 리스너가 올바르게 등록되었는지 확인
3. 브라우저 개발자 도구에서 콘솔 에러 확인

이 구현을 통해 하이브리드 앱에서 웹뷰와 네이티브 간 로그인 세션 공유 문제를 해결하고, 카드 추가 기능을 안정적으로 사용할 수 있습니다.
