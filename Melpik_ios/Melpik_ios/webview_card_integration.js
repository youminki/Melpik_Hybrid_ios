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
  fetch("/api/cards", {
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
function initializeApp() {
  console.log("=== initializeApp called ===");

  // 네이티브 앱에서 로그인 정보를 받을 때까지 대기
  if (isNativeApp()) {
    console.log("Native app detected, waiting for login info...");
    // 네이티브에서 로그인 정보를 전달할 때까지 대기
    // 이벤트 리스너가 이미 등록되어 있으므로 자동으로 처리됨
  } else {
    console.log("Web environment detected, checking existing login state...");
    // 웹 환경에서는 인스타그램 방식 로그인 상태 확인
    const isLoggedIn = checkInstagramLoginStatus();
    if (isLoggedIn) {
      console.log("Found existing login state with keep login");
      loadCardList();
    } else {
      console.log("No existing login state found");
    }
  }
}

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
function checkInstagramLoginStatus() {
  console.log("=== checkInstagramLoginStatus called ===");

  // localStorage와 sessionStorage 모두 확인
  const localToken = localStorage.getItem("accessToken");
  const sessionToken = sessionStorage.getItem("accessToken");
  const cookieToken = getCookie("accessToken");

  const token = localToken || sessionToken || cookieToken;

  if (!token) {
    console.log("토큰이 없음");
    return false;
  }

  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    const currentTime = Date.now() / 1000;

    // 토큰이 만료되었는지 확인
    if (payload.exp && payload.exp < currentTime) {
      console.log("토큰이 만료되어 로그인 상태 유지 불가");
      handleWebLogout();
      return false;
    }

    console.log("인스타그램 방식 로그인 상태 유지 가능");
    return true;
  } catch (error) {
    console.log("토큰 파싱 오류로 로그인 상태 유지 불가:", error);
    handleWebLogout();
    return false;
  }
}

// 22. 인스타그램 방식: 로그인 상태 유지 설정 가져오기
function getKeepLoginSetting() {
  const keepLogin = localStorage.getItem("keepLoginSetting") === "true";
  console.log("Keep login setting:", keepLogin);
  return keepLogin;
}

// 23. 쿠키 가져오기 헬퍼 함수
function getCookie(name) {
  const value = "; " + document.cookie;
  const parts = value.split("; " + name + "=");
  if (parts.length === 2) return parts.pop().split(";").shift();
  return null;
}

// 24. 인스타그램 방식: 로그인 상태 유지 토큰 저장
function saveTokensWithKeepLogin(accessToken, refreshToken, keepLogin = false) {
  console.log("=== saveTokensWithKeepLogin called ===");
  console.log("keepLogin:", keepLogin);

  // 로그인 상태 유지 설정 저장
  localStorage.setItem("keepLoginSetting", keepLogin.toString());
  sessionStorage.setItem("keepLoginSetting", keepLogin.toString());
  document.cookie = "keepLoginSetting=" + keepLogin + "; path=/; max-age=86400";
  console.log("로그인 상태 유지 설정 저장:", keepLogin);

  if (keepLogin) {
    // 로그인 상태 유지: localStorage에 저장 (영구 보관)
    localStorage.setItem("accessToken", accessToken);
    if (refreshToken) {
      localStorage.setItem("refreshToken", refreshToken);
    }
    console.log("localStorage에 토큰 저장됨 (로그인 상태 유지)");
  } else {
    // 세션 유지: sessionStorage에 저장 (브라우저 닫으면 삭제)
    sessionStorage.setItem("accessToken", accessToken);
    if (refreshToken) {
      sessionStorage.setItem("refreshToken", refreshToken);
    }
    console.log("sessionStorage에 토큰 저장됨 (세션 유지)");
  }

  // 쿠키에도 저장 (웹뷰 호환성)
  document.cookie =
    "accessToken=" + accessToken + "; path=/; secure; samesite=strict";
  if (refreshToken) {
    document.cookie =
      "refreshToken=" + refreshToken + "; path=/; secure; samesite=strict";
  }

  console.log("인스타그램 방식 토큰 저장 완료");
}

// 25. 인스타그램 방식: 로그인 상태 유지 설정 저장
function setKeepLoginSetting(enabled) {
  console.log("Setting keep login to:", enabled);
  localStorage.setItem("keepLoginSetting", enabled.toString());

  // 앱에도 설정 전달
  if (isNativeApp() && window.nativeApp && window.nativeApp.setKeepLogin) {
    window.nativeApp.setKeepLogin(enabled);
  }
}

// 26. 인스타그램 방식: 로그인 상태 유지 테스트 함수
function testInstagramLoginStatus() {
  console.log("=== testInstagramLoginStatus called ===");

  // 현재 로그인 상태 확인
  const isLoggedIn = checkInstagramLoginStatus();
  console.log("Current login status:", isLoggedIn);

  // keepLogin 설정 확인
  const keepLogin = getKeepLoginSetting();
  console.log("Keep login setting:", keepLogin);

  // 저장소 상태 확인
  const localToken = localStorage.getItem("accessToken");
  const sessionToken = sessionStorage.getItem("accessToken");
  const cookieToken = getCookie("accessToken");

  console.log("Storage status:");
  console.log("- localStorage token:", localToken ? "exists" : "nil");
  console.log("- sessionStorage token:", sessionToken ? "exists" : "nil");
  console.log("- cookie token:", cookieToken ? "exists" : "nil");

  return {
    isLoggedIn: isLoggedIn,
    keepLogin: keepLogin,
    hasLocalToken: !!localToken,
    hasSessionToken: !!sessionToken,
    hasCookieToken: !!cookieToken,
  };
}

// 19. 인스타그램 방식: 웹에서 로그인 성공 시 앱에 토큰 전달
// 웹사이트에서 로그인 성공 시 이 함수를 호출하여 앱과 웹뷰를 동기화
// 사용 예시: handleWebLoginSuccess({token: "access_token", id: "user_id", email: "user@email.com", name: "User Name", keepLogin: true})
function handleWebLoginSuccess(loginData) {
  console.log("=== handleWebLoginSuccess called ===");
  console.log("Login data:", loginData);

  // 웹에서 로그인 성공 시 앱에 토큰 전달
  if (isNativeApp() && window.nativeApp && window.nativeApp.saveLoginInfo) {
    console.log("Sending login info to native app...");
    window.nativeApp.saveLoginInfo(loginData);
  } else {
    console.log("Native app not available, saving to localStorage only");
  }

  // 인스타그램 방식: 로그인 상태 유지 설정에 따라 저장소 선택
  const keepLogin = loginData.keepLogin || false;
  const storage = keepLogin ? localStorage : sessionStorage;

  console.log("Keep login setting:", keepLogin);
  console.log("Using storage:", keepLogin ? "localStorage" : "sessionStorage");

  // 웹 앱에 저장 (로그인 상태 유지 설정에 따라)
  storage.setItem("accessToken", loginData.token);
  storage.setItem("userId", loginData.id);
  storage.setItem("userEmail", loginData.email);
  storage.setItem("userName", loginData.name);
  if (loginData.refreshToken) {
    storage.setItem("refreshToken", loginData.refreshToken);
  }
  if (loginData.expiresAt) {
    storage.setItem("tokenExpiresAt", loginData.expiresAt);
  }
  storage.setItem("isLoggedIn", "true");
  storage.setItem("keepLoginSetting", keepLogin.toString()); // 웹에서도 저장

  // 로그인 상태 유지 설정을 localStorage에 저장 (설정은 항상 유지)
  localStorage.setItem("keepLoginSetting", keepLogin.toString());

  // 웹 앱 상태 업데이트
  updateLoginState(true);

  console.log("✅ Web login success processed with keep login:", keepLogin);
}

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

// 앱 초기화
document.addEventListener("DOMContentLoaded", function () {
  console.log("=== DOM Content Loaded ===");
  initializeApp();

  // 5초 후 로그인 상태 재확인 (네이티브에서 지연 전송 가능성 대비)
  setTimeout(() => {
    console.log("Checking login status after 5 seconds...");
    checkLoginStatus();
  }, 5000);
});

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
