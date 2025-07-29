// 웹뷰에서 카드 추가 기능 사용 예시

// 1. 네이티브 앱 환경 확인
function isNativeApp() {
  const isNative = typeof window.nativeApp !== "undefined";
  console.log("Native app check:", isNative);
  return isNative;
}

// 2. 카드 추가 버튼 클릭 시 네이티브 호출
function handleCardAddClick() {
  console.log("handleCardAddClick called");

  if (isNativeApp()) {
    console.log("Calling native addCard...");
    // 네이티브 앱에서 카드 추가 화면 표시
    window.nativeApp.addCard();
  } else {
    console.log("Using web card add form...");
    // 웹 환경에서는 기존 웹 카드 추가 로직 실행
    showWebCardAddForm();
  }
}

// 3. 네이티브에서 카드 추가 완료 이벤트 수신
document.addEventListener("cardAddComplete", function (event) {
  console.log("cardAddComplete event received:", event.detail);
  const { success, errorMessage } = event.detail;

  if (success) {
    // 카드 추가 성공
    showSuccessMessage("카드가 성공적으로 추가되었습니다.");
    refreshCardList();
  } else {
    // 카드 추가 실패
    showErrorMessage(errorMessage || "카드 추가에 실패했습니다.");
  }
});

// 4. 카드 목록 새로고침 이벤트 수신
document.addEventListener("cardListRefresh", function () {
  console.log("cardListRefresh event received");
  refreshCardList();
});

// 5. 네이티브 로그인 성공 이벤트 수신
document.addEventListener("nativeLoginSuccess", function (event) {
  console.log("=== nativeLoginSuccess event received ===");
  console.log("Event detail:", event.detail);

  const { userId, userEmail, userName, accessToken } = event.detail;

  // 로그인 정보를 웹 앱에 저장
  localStorage.setItem("accessToken", accessToken);
  localStorage.setItem("userId", userId);
  localStorage.setItem("userEmail", userEmail);
  localStorage.setItem("userName", userName);

  console.log("localStorage after nativeLoginSuccess:");
  console.log("accessToken:", localStorage.getItem("accessToken"));
  console.log("userId:", localStorage.getItem("userId"));
  console.log("userEmail:", localStorage.getItem("userEmail"));
  console.log("userName:", localStorage.getItem("userName"));

  // 웹 앱 상태 업데이트
  updateLoginState(true);

  console.log("✅ Native login success processed");
});

// 6. 기존 로그인 정보 수신 이벤트 (호환성)
document.addEventListener("loginInfoReceived", function (event) {
  console.log("=== loginInfoReceived event received ===");
  console.log("Event detail:", event.detail);

  if (event.detail && event.detail.isLoggedIn && event.detail.userInfo) {
    const { userInfo } = event.detail;

    // 로그인 정보를 웹 앱에 저장
    localStorage.setItem("accessToken", userInfo.token);
    localStorage.setItem("userId", userInfo.id);
    localStorage.setItem("userEmail", userInfo.email);
    localStorage.setItem("userName", userInfo.name);

    if (userInfo.refreshToken) {
      localStorage.setItem("refreshToken", userInfo.refreshToken);
    }

    console.log("localStorage after loginInfoReceived:");
    console.log("accessToken:", localStorage.getItem("accessToken"));
    console.log("userId:", localStorage.getItem("userId"));
    console.log("userEmail:", localStorage.getItem("userEmail"));
    console.log("userName:", localStorage.getItem("userName"));

    // 웹 앱 상태 업데이트
    updateLoginState(true);

    console.log("✅ Login info received and processed");
  }
});

// 6-1. 인스타그램 방식: 토큰 갱신 이벤트 수신
document.addEventListener("tokenRefreshed", function (event) {
  console.log("=== tokenRefreshed event received ===");
  console.log("Event detail:", event.detail);

  if (event.detail && event.detail.tokenData) {
    const { tokenData } = event.detail;

    // 새로운 토큰으로 업데이트
    localStorage.setItem("accessToken", tokenData.token);
    if (tokenData.refreshToken) {
      localStorage.setItem("refreshToken", tokenData.refreshToken);
    }
    if (tokenData.expiresAt) {
      localStorage.setItem("tokenExpiresAt", tokenData.expiresAt);
    }

    sessionStorage.setItem("accessToken", tokenData.token);
    if (tokenData.refreshToken) {
      sessionStorage.setItem("refreshToken", tokenData.refreshToken);
    }

    // 쿠키 업데이트
    document.cookie =
      "accessToken=" + tokenData.token + "; path=/; max-age=86400";

    // 전역 변수 업데이트
    window.accessToken = tokenData.token;

    console.log("✅ Token refreshed in all storages");
  }
});

// 6-2. 인스타그램 방식: 로그아웃 이벤트 수신
document.addEventListener("logoutSuccess", function () {
  console.log("=== logoutSuccess event received ===");

  // 모든 로그인 관련 데이터 제거
  localStorage.removeItem("accessToken");
  localStorage.removeItem("userId");
  localStorage.removeItem("userEmail");
  localStorage.removeItem("userName");
  localStorage.removeItem("refreshToken");
  localStorage.removeItem("tokenExpiresAt");
  localStorage.removeItem("isLoggedIn");
  localStorage.removeItem("keepLoginSetting");

  sessionStorage.removeItem("accessToken");
  sessionStorage.removeItem("userId");
  sessionStorage.removeItem("userEmail");
  sessionStorage.removeItem("userName");
  sessionStorage.removeItem("refreshToken");
  sessionStorage.removeItem("tokenExpiresAt");
  sessionStorage.removeItem("isLoggedIn");
  sessionStorage.removeItem("keepLoginSetting");

  // 쿠키 제거
  document.cookie =
    "accessToken=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie = "userId=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie = "userEmail=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie =
    "isLoggedIn=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie =
    "keepLoginSetting=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";

  // 전역 변수 제거
  delete window.accessToken;
  delete window.userId;
  delete window.userEmail;
  delete window.userName;
  delete window.isLoggedIn;
  delete window.keepLogin;

  // 웹 앱 상태 업데이트
  updateLoginState(false);

  console.log("✅ Logout completed - all data removed");
});

// 6-3. 인스타그램 방식: keepLogin 설정 변경 이벤트 수신
document.addEventListener("keepLoginSettingChanged", function (event) {
  console.log("=== keepLoginSettingChanged event received ===");
  console.log("Event detail:", event.detail);

  if (event.detail && event.detail.keepLogin !== undefined) {
    const { keepLogin } = event.detail;

    // 로그인 상태 유지 설정 저장
    localStorage.setItem("keepLoginSetting", keepLogin.toString());
    sessionStorage.setItem("keepLoginSetting", keepLogin.toString());
    document.cookie =
      "keepLoginSetting=" + keepLogin + "; path=/; max-age=86400";

    console.log("Keep login setting updated:", keepLogin);
  }
});

// 6-4. 인스타그램 방식: 로그인 성공 이벤트 수신 (keepLogin 포함)
document.addEventListener("loginSuccess", function (event) {
  console.log("=== loginSuccess event received ===");
  console.log("Event detail:", event.detail);

  if (event.detail && event.detail.isLoggedIn && event.detail.userInfo) {
    const { userInfo, keepLogin } = event.detail;

    // 로그인 상태 유지 설정 저장
    if (keepLogin !== undefined) {
      localStorage.setItem("keepLoginSetting", keepLogin.toString());
      sessionStorage.setItem("keepLoginSetting", keepLogin.toString());
      document.cookie =
        "keepLoginSetting=" + keepLogin + "; path=/; max-age=86400";
      console.log("Keep login setting saved:", keepLogin);
    }

    // 로그인 정보를 웹 앱에 저장
    localStorage.setItem("accessToken", userInfo.token);
    localStorage.setItem("userId", userInfo.id);
    localStorage.setItem("userEmail", userInfo.email);
    localStorage.setItem("userName", userInfo.name);

    if (userInfo.refreshToken) {
      localStorage.setItem("refreshToken", userInfo.refreshToken);
    }

    // sessionStorage에도 저장 (세션 유지)
    sessionStorage.setItem("accessToken", userInfo.token);
    sessionStorage.setItem("userId", userInfo.id);
    sessionStorage.setItem("userEmail", userInfo.email);
    sessionStorage.setItem("userName", userInfo.name);

    if (userInfo.refreshToken) {
      sessionStorage.setItem("refreshToken", userInfo.refreshToken);
    }

    // 쿠키에도 저장
    document.cookie =
      "accessToken=" + userInfo.token + "; path=/; max-age=86400";
    document.cookie = "userId=" + userInfo.id + "; path=/; max-age=86400";
    document.cookie = "userEmail=" + userInfo.email + "; path=/; max-age=86400";
    document.cookie = "isLoggedIn=true; path=/; max-age=86400";

    // 전역 변수 설정
    window.accessToken = userInfo.token;
    window.userId = userInfo.id;
    window.userEmail = userInfo.email;
    window.userName = userInfo.name;
    window.isLoggedIn = true;
    window.keepLogin = keepLogin;

    console.log("✅ Login success processed with keep login:", keepLogin);
  }
});

// 7. 네이티브 로그아웃 이벤트 수신
document.addEventListener("nativeLogout", function () {
  console.log("=== nativeLogout event received ===");

  // 로그인 정보 제거
  localStorage.removeItem("accessToken");
  localStorage.removeItem("userId");
  localStorage.removeItem("userEmail");
  localStorage.removeItem("userName");
  localStorage.removeItem("refreshToken");
  localStorage.removeItem("tokenExpiresAt");

  // 웹 앱 상태 업데이트
  updateLoginState(false);

  console.log("✅ Native logout processed");
});

// 8. 웹 환경에서 카드 추가 폼 표시
function showWebCardAddForm() {
  // 기존 웹 카드 추가 로직
  console.log("Showing web card add form");
  // 여기에 웹 카드 추가 폼 표시 로직 구현
}

// 9. 카드 목록 새로고침
function refreshCardList() {
  console.log("=== refreshCardList called ===");
  // 카드 목록을 다시 불러오는 로직 구현
  loadCardList();
}

// 10. 로그인 상태 업데이트
function updateLoginState(isLoggedIn) {
  console.log("updateLoginState called with isLoggedIn:", isLoggedIn);

  if (isLoggedIn) {
    // 로그인 상태 UI 업데이트
    document.body.classList.add("logged-in");
    showUserInfo();
    console.log("✅ Login state updated to logged in");
  } else {
    // 로그아웃 상태 UI 업데이트
    document.body.classList.remove("logged-in");
    hideUserInfo();
    console.log("✅ Login state updated to logged out");
  }
}

// 11. 사용자 정보 표시
function showUserInfo() {
  const userName = localStorage.getItem("userName");
  const userEmail = localStorage.getItem("userEmail");

  console.log("showUserInfo called:");
  console.log("userName:", userName);
  console.log("userEmail:", userEmail);

  // 사용자 정보를 UI에 표시하는 로직
  // 예: 헤더에 사용자 이름 표시
  const userInfoElement = document.querySelector(".user-info");
  if (userInfoElement) {
    userInfoElement.textContent = userName || userEmail || "사용자";
    userInfoElement.style.display = "block";
  }
}

// 12. 사용자 정보 숨기기
function hideUserInfo() {
  console.log("hideUserInfo called");

  // 사용자 정보를 UI에서 숨기는 로직
  const userInfoElement = document.querySelector(".user-info");
  if (userInfoElement) {
    userInfoElement.style.display = "none";
  }
}

// 13. 카드 목록 로드
function loadCardList() {
  console.log("=== loadCardList called ===");
  const accessToken = localStorage.getItem("accessToken");

  console.log("accessToken from localStorage:", accessToken);

  if (!accessToken) {
    console.log("❌ No access token available");
    return;
  }

  console.log("✅ Access token found, loading card list...");

  // API 호출하여 카드 목록 가져오기
  fetch("https://api.stylewh.com/api/cards", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  })
    .then((response) => {
      console.log("API response status:", response.status);
      return response.json();
    })
    .then((data) => {
      console.log("Card list loaded:", data);
      // 카드 목록을 UI에 표시하는 로직
      displayCardList(data);
    })
    .catch((error) => {
      console.error("❌ Error loading card list:", error);
    });
}

// 14. 카드 목록 표시
function displayCardList(cards) {
  console.log("displayCardList called with cards:", cards);
  // 카드 목록을 UI에 표시하는 로직
  // 예: 카드 목록 컨테이너에 카드 정보 표시
}

// 15. 성공 메시지 표시
function showSuccessMessage(message) {
  console.log("Success:", message);
  // 성공 메시지를 UI에 표시하는 로직
  alert(message);
}

// 16. 에러 메시지 표시
function showErrorMessage(message) {
  console.log("Error:", message);
  // 에러 메시지를 UI에 표시하는 로직
  alert(message);
}

// 17. 앱 초기화 시 로그인 상태 확인
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function initializeApp() { ... } // 사용처가 없으므로 주석 처리
// function saveTokensWithKeepLogin(...) { ... } // 사용처가 없으므로 주석 처리
// function setKeepLoginSetting(...) { ... } // 사용처가 없으므로 주석 처리
// function testInstagramLoginStatus() { ... } // 사용처가 없으므로 주석 처리
// function handleWebLoginSuccess(...) { ... } // 사용처가 없으므로 주석 처리

// 18. 로그인 상태 확인 함수
function checkLoginStatus() {
  console.log("=== checkLoginStatus called ===");
  const accessToken = localStorage.getItem("accessToken");
  const userId = localStorage.getItem("userId");
  const userEmail = localStorage.getItem("userEmail");
  const userName = localStorage.getItem("userName");

  console.log("Current localStorage values:");
  console.log("accessToken:", accessToken);
  console.log("userId:", userId);
  console.log("userEmail:", userEmail);
  console.log("userName:", userName);

  if (accessToken) {
    console.log("✅ User is logged in");
    updateLoginState(true);
  } else {
    console.log("❌ User is not logged in");
    updateLoginState(false);
  }
}

// 21. 인스타그램 방식: 로그인 상태 유지 확인 함수
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function checkInstagramLoginStatus() { ... } // 사용처가 없으므로 주석 처리

// 22. 인스타그램 방식: 로그인 상태 유지 설정 가져오기
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function getKeepLoginSetting() { ... } // 사용처가 없으므로 주석 처리

// 23. 쿠키 가져오기 헬퍼 함수
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function getCookie(name) { ... } // 사용처가 없으므로 주석 처리

// 24. 인스타그램 방식: 로그인 상태 유지 토큰 저장
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function saveTokensWithKeepLogin(accessToken, refreshToken, keepLogin = false) { ... } // 사용처가 없으므로 주석 처리

// 25. 인스타그램 방식: 로그인 상태 유지 설정 저장
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function setKeepLoginSetting(enabled) { ... } // 사용처가 없으므로 주석 처리

// 26. 인스타그램 방식: 로그인 상태 유지 테스트 함수
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function testInstagramLoginStatus() { ... } // 사용처가 없으므로 주석 처리

// 19. 인스타그램 방식: 웹에서 로그인 성공 시 앱에 토큰 전달
// 웹사이트에서 로그인 성공 시 이 함수를 호출하여 앱과 웹뷰를 동기화
// 사용 예시: handleWebLoginSuccess({token: "access_token", id: "user_id", email: "user@email.com", name: "User Name", keepLogin: true})
// 사용되지 않는 함수 및 변수 정리 (linter 에러 방지)
// function handleWebLoginSuccess(loginData) { ... } // 사용처가 없으므로 주석 처리

// 20. 인스타그램 방식: 웹에서 로그아웃 시 앱에 알림
// 웹사이트에서 로그아웃 시 이 함수를 호출하여 앱과 웹뷰를 동기화
// 사용 예시: handleWebLogout()
function handleWebLogout() {
  console.log("=== handleWebLogout called ===");

  // 웹에서 로그아웃 시 앱에 알림
  if (isNativeApp() && window.nativeApp && window.nativeApp.logout) {
    console.log("Sending logout to native app...");
    window.nativeApp.logout();
  }

  // 웹 앱에서도 로그아웃 처리
  localStorage.removeItem("accessToken");
  localStorage.removeItem("userId");
  localStorage.removeItem("userEmail");
  localStorage.removeItem("userName");
  localStorage.removeItem("refreshToken");
  localStorage.removeItem("tokenExpiresAt");
  localStorage.removeItem("isLoggedIn");
  localStorage.removeItem("keepLoginSetting"); // 웹에서도 제거

  // 웹 앱 상태 업데이트
  updateLoginState(false);

  console.log("✅ Web logout processed");
}

// 앱 실행 시 자동로그인 시도 (네이티브 미연동 대비)
document.addEventListener("DOMContentLoaded", function () {
  // 네이티브 환경이 아니거나, 네이티브에서 토큰 전달이 누락된 경우 대비
  setTimeout(function () {
    if (
      !window.nativeApp ||
      typeof window.nativeApp.checkLoginStatus !== "function"
    ) {
      tryAutoLogin();
    }
  }, 1500); // 네이티브 토큰 전달 대기 후 실행
});

function tryAutoLogin() {
  const accessToken = localStorage.getItem("accessToken");
  const refreshToken = localStorage.getItem("refreshToken");
  if (accessToken && !isTokenExpired(accessToken)) {
    console.log("[AutoLogin] accessToken 유효, 자동 로그인 처리");
    updateLoginState(true);
  } else if (refreshToken) {
    console.log("[AutoLogin] accessToken 만료, refreshToken으로 갱신 시도");
    refreshAccessTokenWithAPI(refreshToken);
  } else {
    console.log("[AutoLogin] 토큰 없음, 로그아웃 처리");
    handleWebLogout();
  }
}

function isTokenExpired(token) {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    const currentTime = Date.now() / 1000;
    return payload.exp && payload.exp < currentTime;
  } catch (e) {
    return true;
  }
}

function refreshAccessTokenWithAPI(refreshToken) {
  // 실제 서버 API 엔드포인트로 교체
  fetch("https://api.stylewh.com/auth/refresh", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
  })
    .then((res) => res.json())
    .then((data) => {
      if (data && data.token) {
        localStorage.setItem("accessToken", data.token);
        if (data.refreshToken)
          localStorage.setItem("refreshToken", data.refreshToken);
        if (data.expiresAt)
          localStorage.setItem("tokenExpiresAt", data.expiresAt);
        updateLoginState(true);
        console.log("[AutoLogin] refreshToken으로 accessToken 갱신 성공");
      } else {
        handleWebLogout();
        console.log("[AutoLogin] refreshToken 갱신 실패, 로그아웃 처리");
      }
    })
    .catch((err) => {
      handleWebLogout();
      console.log("[AutoLogin] refreshToken 갱신 에러:", err);
    });
}

// 카드 추가 버튼에 이벤트 리스너 추가 예시
document.addEventListener("click", function (event) {
  if (event.target.matches(".card-add-button")) {
    console.log("Card add button clicked");
    event.preventDefault();
    handleCardAddClick();
  }
});

// 페이지 로드 완료 후 로그인 상태 확인
window.addEventListener("load", function () {
  console.log("=== Window Load Event ===");
  setTimeout(() => {
    console.log("Checking login status after window load...");
    checkLoginStatus();
  }, 2000);
});

// =============================
// [테스트용] 네이티브 브릿지 호출 버튼
// =============================
window.addEventListener("DOMContentLoaded", function () {
  var testBtn = document.createElement("button");
  testBtn.innerText = "[TEST] saveLoginInfo 브릿지 호출";
  testBtn.style.position = "fixed";
  testBtn.style.bottom = "20px";
  testBtn.style.right = "20px";
  testBtn.style.zIndex = 9999;
  testBtn.style.background = "#222";
  testBtn.style.color = "#fff";
  testBtn.style.padding = "12px 18px";
  testBtn.style.borderRadius = "8px";
  testBtn.style.fontWeight = "bold";
  testBtn.onclick = function () {
    console.log("[BRIDGE] saveLoginInfo 테스트 호출");
    if (
      window.webkit &&
      window.webkit.messageHandlers &&
      window.webkit.messageHandlers.saveLoginInfo
    ) {
      const testRefreshToken =
        "test_refresh_token_" +
        Date.now() +
        "_" +
        Math.random().toString(36).substr(2, 9);
      console.log("테스트 refreshToken 생성:", testRefreshToken);

      window.webkit.messageHandlers.saveLoginInfo.postMessage({
        loginData: {
          id: "test_id",
          email: "test@me1pik.com",
          name: "테스트",
          token: "test_access_token_" + Date.now(),
          refreshToken: testRefreshToken,
          expiresAt: new Date(Date.now() + 3600000).toISOString(),
          keepLogin: true,
        },
      });
    } else {
      console.log("saveLoginInfo 브릿지 없음");
    }
  };
  document.body.appendChild(testBtn);
});
