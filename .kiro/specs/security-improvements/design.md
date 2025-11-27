# Design Document - Security Improvements EcoTrack

## Overview

Design ini mengimplementasikan security improvements untuk aplikasi EcoTrack berdasarkan hasil audit keamanan. Fokus utama adalah mengatasi 8 security findings dengan prioritas tinggi dan menengah yang dapat diimplementasikan dalam jangka pendek untuk meningkatkan postur keamanan aplikasi secara signifikan.

Implementasi akan dilakukan secara bertahap dengan prioritas pada High Risk findings terlebih dahulu, diikuti dengan Medium Risk findings. Design ini mempertimbangkan arsitektur Flutter/Supabase yang sudah ada dan memastikan backward compatibility.

## Architecture

### Security Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
├─────────────────────────────────────────────────────────────┤
│  Security Layer                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Runtime         │ │ Input           │ │ Error           ││
│  │ Protection      │ │ Validation      │ │ Handling        ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  Application Layer                                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Session         │ │ Secure          │ │ Security        ││
│  │ Management      │ │ Storage         │ │ Monitoring      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  Network Layer                                              │
│  ┌─────────────────┐ ┌─────────────────┐                   │
│  │ Certificate     │ │ Secure Config   │                   │
│  │ Pinning         │ │ Management      │                   │
│  └─────────────────┘ └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Edge Functions  │ │ Row Level       │ │ Auth            ││
│  │ (Validation)    │ │ Security        │ │ Management      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Security Components Integration

1. **Configuration Layer**: Environment-based configuration management
2. **Storage Layer**: Encrypted local storage dengan hardware-backed security
3. **Network Layer**: Certificate pinning dan secure HTTP client
4. **Session Layer**: Proper session management dengan timeout dan validation
5. **Validation Layer**: Client-side dan server-side input validation
6. **Monitoring Layer**: Security event logging dan monitoring
7. **Protection Layer**: Runtime protection terhadap common attacks

## Components and Interfaces

### 1. Secure Configuration Management

```dart
// Interface untuk configuration management
abstract class ISecureConfig {
  String get supabaseUrl;
  String get supabaseAnonKey;
  String get environment;
  bool get isProduction;
  
  Future<void> initialize();
  T getConfig<T>(String key, T defaultValue);
}

// Implementation
class EnvironmentConfig implements ISecureConfig {
  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const String _environmentKey = 'ENVIRONMENT';
}
```

### 2. Secure Storage Service

```dart
// Interface untuk secure storage
abstract class ISecureStorage {
  Future<void> store(String key, String value);
  Future<String?> retrieve(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
}

// Implementation dengan encryption
class FlutterSecureStorageService implements ISecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );
}
```

### 3. Session Management Service

```dart
// Interface untuk session management
abstract class ISessionManager {
  Future<bool> isSessionValid();
  Future<void> refreshSession();
  Future<void> invalidateSession();
  Future<void> startSessionMonitoring();
  void stopSessionMonitoring();
}

// Implementation
class SupabaseSessionManager implements ISessionManager {
  static const int _sessionTimeoutMinutes = 60;
  static const int _refreshThresholdMinutes = 10;
  Timer? _sessionTimer;
}
```

### 4. Input Validation Service

```dart
// Interface untuk input validation
abstract class IInputValidator {
  Future<ValidationResult> validateEmail(String email);
  Future<ValidationResult> validatePassword(String password);
  Future<ValidationResult> validateRegistration(RegistrationData data);
  ValidationResult validateClientSide(String input, ValidationType type);
}

// Validation result model
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final String? sanitizedInput;
}
```

### 5. Certificate Pinning Service

```dart
// Interface untuk certificate pinning
abstract class ICertificatePinning {
  Future<void> initialize();
  HttpClient createSecureHttpClient();
  Future<bool> validateCertificate(String host);
}

// Implementation
class SupbaseCertificatePinning implements ICertificatePinning {
  static const List<String> _allowedFingerprints = [
    'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Supabase cert
  ];
}
```

### 6. Security Monitoring Service

```dart
// Interface untuk security monitoring
abstract class ISecurityMonitor {
  void logSecurityEvent(SecurityEvent event);
  void logAuthenticationAttempt(AuthAttempt attempt);
  void logSuspiciousActivity(SuspiciousActivity activity);
  Future<List<SecurityEvent>> getSecurityLogs();
}

// Security event models
class SecurityEvent {
  final String eventType;
  final DateTime timestamp;
  final String userId;
  final Map<String, dynamic> metadata;
  final SecurityLevel level;
}
```

## Data Models

### Security Configuration Model

```dart
class SecurityConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String environment;
  final bool enableCertificatePinning;
  final bool enableRuntimeProtection;
  final int sessionTimeoutMinutes;
  final bool enableSecurityLogging;
  
  const SecurityConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.environment,
    this.enableCertificatePinning = true,
    this.enableRuntimeProtection = true,
    this.sessionTimeoutMinutes = 60,
    this.enableSecurityLogging = true,
  });
}
```

### Session Data Model

```dart
class SessionData {
  final String userId;
  final String sessionId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastActivity;
  final String deviceId;
  final bool isValid;
  
  SessionData({
    required this.userId,
    required this.sessionId,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActivity,
    required this.deviceId,
    required this.isValid,
  });
}
```

### Security Event Models

```dart
enum SecurityLevel { low, medium, high, critical }

enum SecurityEventType {
  authentication,
  authorization,
  dataAccess,
  configurationChange,
  suspiciousActivity,
  runtimeProtection,
  networkSecurity,
}

class AuthAttempt {
  final String email;
  final bool success;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final String? failureReason;
}

class SuspiciousActivity {
  final String activityType;
  final String description;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> context;
  final SecurityLevel riskLevel;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Configuration Management Properties

**Property 1: Environment-based configuration loading**
*For any* application startup, configuration values should be loaded from environment variables and never from hardcoded values in source code
**Validates: Requirements 1.1**

**Property 2: Environment isolation**
*For any* build configuration, development builds should never contain production configuration values
**Validates: Requirements 1.2**

**Property 3: Secure configuration access**
*For any* Supabase configuration access, the system should retrieve values through the secure configuration service
**Validates: Requirements 1.3**

**Property 4: Build-time configuration support**
*For any* dart-define parameter provided at build time, the system should properly incorporate it into the configuration
**Validates: Requirements 1.5**

### Secure Storage Properties

**Property 5: Encrypted storage usage**
*For any* authentication data storage operation, the data should be stored using encrypted storage mechanisms
**Validates: Requirements 2.1**

**Property 6: Secure data retrieval**
*For any* stored user data retrieval, the system should use secure decryption through device keystore
**Validates: Requirements 2.2**

**Property 7: Hardware-backed encryption**
*For any* device with hardware security module, the system should utilize hardware-backed encryption when available
**Validates: Requirements 2.4**

**Property 8: Biometric protection integration**
*For any* device with biometric capabilities, the system should optionally protect sensitive data access with biometric authentication
**Validates: Requirements 2.5**

### Session Management Properties

**Property 9: Session timeout enforcement**
*For any* user session, the session should automatically expire after the configured timeout period
**Validates: Requirements 3.1**

**Property 10: Automatic logout on expiry**
*For any* expired session, the system should automatically log out the user and clear all session data
**Validates: Requirements 3.2**

**Property 11: Server-side session validation**
*For any* session validity check, the system should validate against server-side session state
**Validates: Requirements 3.3**

**Property 12: Secure token refresh**
*For any* session refresh operation, the system should use secure token refresh mechanisms
**Validates: Requirements 3.4**

**Property 13: Periodic session validation**
*For any* active application session, the system should periodically validate session integrity
**Validates: Requirements 3.5**

### Input Validation Properties

**Property 14: Dual validation enforcement**
*For any* user input submission, the system should perform validation on both client-side and server-side
**Validates: Requirements 4.1**

**Property 15: Input sanitization**
*For any* user input processing, the system should sanitize and validate data before processing
**Validates: Requirements 4.2**

**Property 16: Safe error messaging**
*For any* validation failure, the system should provide user-friendly error messages without exposing system internals
**Validates: Requirements 4.3**

**Property 17: Parameterized database queries**
*For any* database interaction, the system should use parameterized queries to prevent injection attacks
**Validates: Requirements 4.4**

**Property 18: API rate limiting**
*For any* API endpoint with rate limiting, the system should enforce appropriate rate limits
**Validates: Requirements 4.5**

### Certificate Pinning Properties

**Property 19: Certificate validation**
*For any* connection to Supabase, the system should validate SSL certificates against pinned certificates
**Validates: Requirements 5.1**

**Property 20: Certificate rotation support**
*For any* certificate update, the system should support certificate rotation without breaking functionality
**Validates: Requirements 5.3**

**Property 21: Secure HTTP client usage**
*For any* external network request, the system should use certificate-pinned HTTP client
**Validates: Requirements 5.4**

**Property 22: Fallback security measures**
*For any* scenario where certificate pinning is not possible, the system should implement additional security measures
**Validates: Requirements 5.5**

### Error Handling Properties

**Property 23: User-friendly error display**
*For any* system error, the displayed message should be user-friendly without exposing technical details
**Validates: Requirements 6.1**

**Property 24: Secure error logging**
*For any* error logging operation, the system should log detailed information securely without exposing sensitive data
**Validates: Requirements 6.2**

**Property 25: Generic authentication errors**
*For any* authentication failure, the system should provide generic error messages to prevent user enumeration
**Validates: Requirements 6.3**

**Property 26: Network error handling**
*For any* network error, the system should handle it gracefully with appropriate retry mechanisms
**Validates: Requirements 6.4**

**Property 27: Standardized error codes**
*For any* error code usage, the system should implement a standardized error code system
**Validates: Requirements 6.5**

### Runtime Protection Properties

**Property 28: Integrity checking**
*For any* application runtime, the system should perform basic integrity checks
**Validates: Requirements 7.3**

**Property 29: Security event logging**
*For any* detected security threat, the system should log security events appropriately
**Validates: Requirements 7.4**

**Property 30: Limited functionality mode**
*For any* compromised device security, the system should provide options to limit functionality
**Validates: Requirements 7.5**

### Security Monitoring Properties

**Property 31: Detailed security logging**
*For any* security event, the system should log it with appropriate detail level
**Validates: Requirements 8.1**

**Property 32: Authentication event tracking**
*For any* authentication event, the system should track login attempts, failures, and successes
**Validates: Requirements 8.2**

**Property 33: Suspicious activity alerting**
*For any* detected suspicious activity, the system should alert administrators appropriately
**Validates: Requirements 8.3**

**Property 34: Sanitized logging**
*For any* log generation, the system should ensure logs don't contain sensitive user data
**Validates: Requirements 8.4**

**Property 35: Security metrics provision**
*For any* monitoring implementation, the system should provide security metrics and dashboards
**Validates: Requirements 8.5**

## Error Handling

### Security Error Categories

1. **Configuration Errors**
   - Missing environment variables
   - Invalid configuration values
   - Build-time configuration failures

2. **Storage Errors**
   - Encryption/decryption failures
   - Keystore access issues
   - Storage permission problems

3. **Session Errors**
   - Session timeout
   - Invalid session tokens
   - Session refresh failures

4. **Validation Errors**
   - Input validation failures
   - Server-side validation errors
   - Rate limiting violations

5. **Network Security Errors**
   - Certificate pinning failures
   - SSL/TLS handshake errors
   - Network connectivity issues

6. **Runtime Protection Errors**
   - Device security compromise detection
   - Integrity check failures
   - Anti-debugging triggers

### Error Handling Strategy

```dart
// Centralized error handling
class SecurityErrorHandler {
  static const Map<SecurityErrorType, String> _userMessages = {
    SecurityErrorType.configurationMissing: 'Aplikasi tidak dapat dimulai. Silakan hubungi support.',
    SecurityErrorType.sessionExpired: 'Sesi Anda telah berakhir. Silakan login kembali.',
    SecurityErrorType.networkSecurityError: 'Koneksi tidak aman. Periksa jaringan Anda.',
    SecurityErrorType.deviceCompromised: 'Perangkat tidak aman. Beberapa fitur dibatasi.',
  };
  
  static String getUserMessage(SecurityErrorType errorType) {
    return _userMessages[errorType] ?? 'Terjadi kesalahan sistem';
  }
  
  static void logSecurityError(SecurityError error) {
    // Log detailed error for debugging without exposing to user
    SecurityMonitor.instance.logSecurityEvent(
      SecurityEvent.fromError(error)
    );
  }
}
```

## Testing Strategy

### Dual Testing Approach

The security improvements will be tested using both unit testing and property-based testing approaches:

**Unit Testing Focus:**
- Specific security scenarios and edge cases
- Error handling paths
- Integration between security components
- Mock-based testing for external dependencies

**Property-Based Testing Focus:**
- Universal security properties across all inputs
- Configuration loading behavior
- Session management correctness
- Input validation effectiveness
- Certificate pinning reliability

### Property-Based Testing Framework

We will use the **test** package with **faker** for property-based testing in Dart/Flutter:

```yaml
dev_dependencies:
  test: ^1.24.0
  faker: ^2.1.0
  mockito: ^5.4.2
```

### Testing Configuration

- **Minimum iterations per property test:** 100
- **Property test timeout:** 30 seconds per test
- **Coverage target:** >90% for security-critical code
- **Test environment:** Isolated test environment with mock Supabase

### Property Test Implementation Requirements

Each property-based test must:
1. Run a minimum of 100 iterations with randomized inputs
2. Include a comment referencing the specific correctness property from this design document
3. Use the format: `**Feature: security-improvements, Property {number}: {property_text}**`
4. Test the universal behavior across all valid input ranges
5. Include appropriate generators for realistic test data

### Unit Test Implementation Requirements

Unit tests should:
1. Cover specific examples that demonstrate correct security behavior
2. Test error conditions and edge cases
3. Verify integration points between security components
4. Use mocks appropriately to isolate components under test
5. Include tests for security-critical paths and error handling

### Security Test Categories

1. **Configuration Security Tests**
   - Environment variable loading
   - Build-time configuration
   - Configuration validation

2. **Storage Security Tests**
   - Encryption/decryption operations
   - Keystore integration
   - Data cleanup verification

3. **Session Security Tests**
   - Session lifecycle management
   - Timeout enforcement
   - Token refresh mechanisms

4. **Input Validation Tests**
   - Client-side validation
   - Server-side validation
   - Sanitization effectiveness

5. **Network Security Tests**
   - Certificate pinning validation
   - Secure HTTP client behavior
   - SSL/TLS configuration

6. **Runtime Protection Tests**
   - Device security detection
   - Integrity checking
   - Anti-tampering measures

7. **Monitoring Tests**
   - Security event logging
   - Metrics collection
   - Alert generation