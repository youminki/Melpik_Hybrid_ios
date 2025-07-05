// Android Kotlin 카드 추가 기능 구현 예시

import android.content.Context
import android.webkit.*
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import java.util.*

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private lateinit var loginManager: LoginManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        loginManager = LoginManager(this)
        setupWebView()
    }
    
    private fun setupWebView() {
        webView = findViewById(R.id.webView)
        
        // WebView 설정
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = true
            allowContentAccess = true
        }
        
        // JavaScript 인터페이스 추가
        webView.addJavascriptInterface(NativeBridge(), "nativeApp")
        
        // WebViewClient 설정
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // 페이지 로딩 완료 시 로그인 상태 확인 및 전달
                loginManager.checkLoginStatus(webView)
            }
        }
        
        // 초기 URL 로드
        webView.loadUrl("https://me1pik.com")
    }
    
    // 네이티브 브릿지 클래스
    inner class NativeBridge {
        @JavascriptInterface
        fun addCard() {
            runOnUiThread {
                loginManager.handleCardAddRequest(webView) { success, errorMessage ->
                    runOnUiThread {
                        if (success) {
                            // 카드 추가 성공 시 웹뷰에 알림
                            loginManager.notifyCardAddComplete(webView, true)
                            
                            // 카드 목록 새로고침 이벤트 발생
                            val script = "window.dispatchEvent(new CustomEvent('cardListRefresh'));"
                            webView.evaluateJavascript(script, null)
                        } else {
                            // 카드 추가 실패 시 웹뷰에 에러 알림
                            loginManager.notifyCardAddComplete(webView, false, errorMessage)
                        }
                    }
                }
            }
        }
        
        @JavascriptInterface
        fun refreshCardList() {
            runOnUiThread {
                val script = "window.dispatchEvent(new CustomEvent('cardListRefresh'));"
                webView.evaluateJavascript(script, null)
            }
        }
        
        @JavascriptInterface
        fun saveLoginInfo(loginData: String) {
            runOnUiThread {
                loginManager.saveLoginInfo(loginData)
            }
        }
        
        @JavascriptInterface
        fun logout() {
            runOnUiThread {
                loginManager.logout()
            }
        }
    }
}

// 로그인 매니저 클래스
class LoginManager(private val context: Context) {
    private val sharedPreferences = context.getSharedPreferences("login_prefs", Context.MODE_PRIVATE)
    private val keyStore = KeyStore.getInstance("AndroidKeyStore")
    
    init {
        keyStore.load(null)
    }
    
    fun saveLoginInfo(loginData: String) {
        // JSON 파싱 및 저장
        try {
            val jsonObject = JSONObject(loginData)
            val editor = sharedPreferences.edit()
            
            editor.putString("accessToken", jsonObject.getString("accessToken"))
            editor.putString("userId", jsonObject.getString("userId"))
            editor.putString("userEmail", jsonObject.getString("userEmail"))
            editor.putString("userName", jsonObject.getString("userName"))
            editor.putBoolean("isLoggedIn", true)
            
            editor.apply()
            
            // KeyStore에 민감한 정보 저장
            saveToKeyStore("refreshToken", jsonObject.optString("refreshToken", ""))
            
            println("Login info saved successfully")
        } catch (e: Exception) {
            println("Error saving login info: ${e.message}")
        }
    }
    
    fun checkLoginStatus(webView: WebView) {
        val isLoggedIn = sharedPreferences.getBoolean("isLoggedIn", false)
        
        if (isLoggedIn) {
            val accessToken = sharedPreferences.getString("accessToken", "")
            val userId = sharedPreferences.getString("userId", "")
            val userEmail = sharedPreferences.getString("userEmail", "")
            val userName = sharedPreferences.getString("userName", "")
            
            if (!accessToken.isNullOrEmpty()) {
                sendLoginInfoToWeb(webView, accessToken, userId, userEmail, userName)
            } else {
                sendLogoutToWeb(webView)
            }
        } else {
            sendLogoutToWeb(webView)
        }
    }
    
    private fun sendLoginInfoToWeb(webView: WebView, accessToken: String, userId: String, userEmail: String, userName: String) {
        val script = """
            (function() {
                // localStorage에 로그인 정보 저장
                localStorage.setItem('accessToken', '$accessToken');
                localStorage.setItem('userId', '$userId');
                localStorage.setItem('userEmail', '$userEmail');
                localStorage.setItem('userName', '$userName');
                
                // 쿠키에도 토큰 설정
                document.cookie = 'accessToken=$accessToken; path=/; secure; samesite=strict';
                document.cookie = 'userId=$userId; path=/; secure; samesite=strict';
                
                // 로그인 상태 이벤트 발생
                window.dispatchEvent(new CustomEvent('nativeLoginSuccess', {
                    detail: {
                        userId: '$userId',
                        userEmail: '$userEmail',
                        userName: '$userName',
                        accessToken: '$accessToken'
                    }
                }));
                
                console.log('Native login info sent to web');
            })();
        """.trimIndent()
        
        webView.evaluateJavascript(script, null)
    }
    
    private fun sendLogoutToWeb(webView: WebView) {
        val script = """
            (function() {
                // localStorage에서 로그인 정보 제거
                localStorage.removeItem('accessToken');
                localStorage.removeItem('userId');
                localStorage.removeItem('userEmail');
                localStorage.removeItem('userName');
                localStorage.removeItem('refreshToken');
                localStorage.removeItem('tokenExpiresAt');
                
                // 로그아웃 상태 이벤트 발생
                window.dispatchEvent(new CustomEvent('nativeLogout'));
                
                console.log('Native logout state sent to web');
            })();
        """.trimIndent()
        
        webView.evaluateJavascript(script, null)
    }
    
    fun handleCardAddRequest(webView: WebView, completion: (Boolean, String?) -> Unit) {
        // 로그인 상태 확인
        val isLoggedIn = sharedPreferences.getBoolean("isLoggedIn", false)
        val accessToken = sharedPreferences.getString("accessToken", "")
        
        if (!isLoggedIn || accessToken.isNullOrEmpty()) {
            completion(false, "로그인이 필요합니다.")
            return
        }
        
        // 카드 추가 화면을 네이티브로 표시
        showCardAddScreen { success, errorMessage ->
            completion(success, errorMessage)
        }
    }
    
    private fun showCardAddScreen(completion: (Boolean, String?) -> Unit) {
        // 실제 카드 추가 화면을 표시하는 로직
        // 예: CardAddActivity로 이동
        val intent = Intent(context, CardAddActivity::class.java)
        intent.putExtra("completion", completion)
        context.startActivity(intent)
    }
    
    fun notifyCardAddComplete(webView: WebView, success: Boolean, errorMessage: String? = null) {
        val script = """
            (function() {
                window.dispatchEvent(new CustomEvent('cardAddComplete', {
                    detail: {
                        success: $success,
                        errorMessage: '${errorMessage ?: ""}'
                    }
                }));
                
                console.log('Card add complete notification sent to web');
            })();
        """.trimIndent()
        
        webView.evaluateJavascript(script, null)
    }
    
    fun logout() {
        val editor = sharedPreferences.edit()
        editor.clear()
        editor.apply()
        
        // KeyStore에서 토큰 제거
        deleteFromKeyStore("refreshToken")
        
        println("Logout completed")
    }
    
    // KeyStore 관련 메서드들
    private fun saveToKeyStore(key: String, value: String) {
        if (value.isNotEmpty()) {
            try {
                val keyGenerator = KeyGenerator.getInstance("AES", "AndroidKeyStore")
                val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                    key,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .build()
                
                keyGenerator.init(keyGenParameterSpec)
                val secretKey = keyGenerator.generateKey()
                
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.ENCRYPT_MODE, secretKey)
                
                val encryptedBytes = cipher.doFinal(value.toByteArray())
                val combined = cipher.iv + encryptedBytes
                
                val editor = sharedPreferences.edit()
                editor.putString("encrypted_$key", Base64.encodeToString(combined, Base64.DEFAULT))
                editor.apply()
            } catch (e: Exception) {
                println("Error saving to KeyStore: ${e.message}")
            }
        }
    }
    
    private fun loadFromKeyStore(key: String): String? {
        return try {
            val encryptedData = sharedPreferences.getString("encrypted_$key", null)
            if (encryptedData != null) {
                val combined = Base64.decode(encryptedData, Base64.DEFAULT)
                val iv = combined.copyOfRange(0, 12)
                val encryptedBytes = combined.copyOfRange(12, combined.size)
                
                val secretKey = keyStore.getKey(key, null)
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(128, iv))
                
                String(cipher.doFinal(encryptedBytes))
            } else {
                null
            }
        } catch (e: Exception) {
            println("Error loading from KeyStore: ${e.message}")
            null
        }
    }
    
    private fun deleteFromKeyStore(key: String) {
        try {
            keyStore.deleteEntry(key)
            val editor = sharedPreferences.edit()
            editor.remove("encrypted_$key")
            editor.apply()
        } catch (e: Exception) {
            println("Error deleting from KeyStore: ${e.message}")
        }
    }
}

// 카드 추가 액티비티 예시
class CardAddActivity : AppCompatActivity() {
    private lateinit var cardNumberEditText: EditText
    private lateinit var expiryDateEditText: EditText
    private lateinit var cvvEditText: EditText
    private lateinit var cardholderNameEditText: EditText
    private lateinit var addCardButton: Button
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_card_add)
        
        setupViews()
        setupListeners()
    }
    
    private fun setupViews() {
        cardNumberEditText = findViewById(R.id.cardNumberEditText)
        expiryDateEditText = findViewById(R.id.expiryDateEditText)
        cvvEditText = findViewById(R.id.cvvEditText)
        cardholderNameEditText = findViewById(R.id.cardholderNameEditText)
        addCardButton = findViewById(R.id.addCardButton)
    }
    
    private fun setupListeners() {
        addCardButton.setOnClickListener {
            addCard()
        }
        
        // 카드 번호 포맷팅
        cardNumberEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                formatCardNumber(s.toString())
            }
        })
        
        // 만료일 포맷팅
        expiryDateEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                formatExpiryDate(s.toString())
            }
        })
    }
    
    private fun formatCardNumber(input: String) {
        val cleaned = input.replace(" ", "")
        val formatted = cleaned.chunked(4).joinToString(" ")
        cardNumberEditText.setText(formatted)
        cardNumberEditText.setSelection(formatted.length)
    }
    
    private fun formatExpiryDate(input: String) {
        val cleaned = input.replace("/", "")
        if (cleaned.length >= 2) {
            val month = cleaned.substring(0, 2)
            val year = if (cleaned.length >= 4) cleaned.substring(2, 4) else ""
            val formatted = "$month/$year"
            expiryDateEditText.setText(formatted)
            expiryDateEditText.setSelection(formatted.length)
        }
    }
    
    private fun addCard() {
        val cardNumber = cardNumberEditText.text.toString().replace(" ", "")
        val expiryDate = expiryDateEditText.text.toString()
        val cvv = cvvEditText.text.toString()
        val cardholderName = cardholderNameEditText.text.toString()
        
        if (isFormValid(cardNumber, expiryDate, cvv, cardholderName)) {
            // 실제 카드 등록 API 호출
            addCardToServer(cardNumber, expiryDate, cvv, cardholderName)
        } else {
            showError("모든 필드를 올바르게 입력해주세요.")
        }
    }
    
    private fun isFormValid(cardNumber: String, expiryDate: String, cvv: String, cardholderName: String): Boolean {
        return cardNumber.length >= 13 &&
               expiryDate.matches(Regex("\\d{2}/\\d{2}")) &&
               cvv.length == 3 &&
               cardholderName.isNotEmpty()
    }
    
    private fun addCardToServer(cardNumber: String, expiryDate: String, cvv: String, cardholderName: String) {
        // 실제 API 호출 구현
        // 여기서는 시뮬레이션
        Handler(Looper.getMainLooper()).postDelayed({
            // 성공 시뮬레이션
            val success = true
            val errorMessage: String? = null
            
            if (success) {
                showSuccess("카드가 성공적으로 추가되었습니다.")
                setResult(RESULT_OK)
                finish()
            } else {
                showError(errorMessage ?: "카드 등록에 실패했습니다.")
            }
        }, 2000)
    }
    
    private fun showSuccess(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }
    
    private fun showError(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }
} 