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
    // 웹 환경에서는 기존 로그인 상태 확인
    const accessToken = localStorage.getItem("accessToken");
    if (accessToken) {
      console.log("Found existing access token in localStorage");
      updateLoginState(true);
      loadCardList();
    } else {
      console.log("No existing access token found");
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
