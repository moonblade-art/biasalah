# LAPORAN PENGUJIAN AKADEMIK PBL - ECOTRACK

## Informasi Proyek
**Nama Aplikasi**: EcoTrack  
**Platform**: Flutter + Dart  
**Backend**: Supabase (PostgreSQL)  
**Framework Testing**: flutter_test + http package  
**Tanggal Pengujian**: 16 Desember 2024

---

## A. UNIT TEST (5 Service/Fitur)

### Summary
Total **5 service files** dengan **41 test cases**

| No | Service | File | Test Cases | Status |
|----|---------|------|------------|--------|
| 1 | Authentication Validation | `test/unit/auth_service_test.dart` | 7 tests | ✅ PASS |
| 2 | Emission Calculation | `test/unit/emission_calculation_test.dart` | 8 tests | ✅ PASS |
| 3 | Donation Validation | `test/unit/donation_validation_test.dart` | 8 tests | ✅ PASS |
| 4 | Profile Validation | `test/unit/profile_validation_test.dart` | 9 tests | ✅ PASS |
| 5 | Trip Calculation | `test/unit/trip_calculation_test.dart` | 9 tests | ✅ PASS |

**Total**: 41/41 tests PASSING

### Detail Pengujian

#### 1. Authentication Service (`auth_service_test.dart`)
**Fitur yang diuji**: Email validation, password strength, login credentials

**Test Cases**:
- ✅ UNIT-AUTH-001: Valid email format
- ✅ UNIT-AUTH-002: Invalid email format
- ✅ UNIT-AUTH-003: Strong password criteria
- ✅ UNIT-AUTH-004: Weak password detection
- ✅ UNIT-AUTH-005: Password length validation
- ✅ UNIT-AUTH-006: Valid login credentials
- ✅ UNIT-AUTH-007: Invalid credentials rejection

#### 2. Emission Calculation Service (`emission_calculation_test.dart`)
**Fitur yang diuji**: CO₂ calculation, vehicle emission factors

**Test Cases**:
- ✅ UNIT-EMISSION-001: Car emission calculation (0.231 kg/km)
- ✅ UNIT-EMISSION-002: Motorcycle emission (0.117 kg/km)
- ✅ UNIT-EMISSION-003: Bicycle zero emission
- ✅ UNIT-EMISSION-004: Electric vehicle low emission
- ✅ UNIT-EMISSION-005: Emission scales with distance
- ✅ UNIT-EMISSION-006: Zero distance returns zero
- ✅ UNIT-EMISSION-007: Negative distance handling
- ✅ UNIT-EMISSION-008: Emission factors validation

#### 3. Donation Validation Service (`donation_validation_test.dart`)
**Fitur yang diuji**: Amount validation, carbon to IDR conversion

**Test Cases**:
- ✅ UNIT-DONATION-001: Minimum amount (Rp 10,000)
- ✅ UNIT-DONATION-002: Maximum amount (Rp 10,000,000)
- ✅ UNIT-DONATION-003: Carbon to IDR conversion (Rp 5,000/kg)
- ✅ UNIT-DONATION-004: Valid donation range
- ✅ UNIT-DONATION-005: Invalid donation rejection
- ✅ UNIT-DONATION-006: Carbon amount must be positive
- ✅ UNIT-DONATION-007: Amount rounding logic
- ✅ UNIT-DONATION-008: Multiple price tiers

#### 4. Profile Validation Service (`profile_validation_test.dart`)
**Fitur yang diuji**: Name validation, email format, phone format

**Test Cases**:
- ✅ UNIT-PROFILE-001: Valid name acceptance
- ✅ UNIT-PROFILE-002: Invalid name rejection
- ✅ UNIT-PROFILE-003: Name length limits (3-50 chars)
- ✅ UNIT-PROFILE-004: Email format validation
- ✅ UNIT-PROFILE-005: Indonesian phone format (08xxxxxxxxxx)
- ✅ UNIT-PROFILE-006: Profile completeness check
- ✅ UNIT-PROFILE-007: Incomplete profile detection
- ✅ UNIT-PROFILE-008: Special characters in name (apostrophe, hyphen)
- ✅ UNIT-PROFILE-009: Whitespace trimming

#### 5. Trip Calculation Service (`trip_calculation_test.dart`)
**Fitur yang diuji**: GPS distance calculation (Haversine), speed validation

**Test Cases**:
- ✅ UNIT-TRIP-001: Jakarta-Bandung distance (~150km)
- ✅ UNIT-TRIP-002: Same location zero distance
- ✅ UNIT-TRIP-003: Trip duration from timestamps
- ✅ UNIT-TRIP-004: Average speed calculation (60 km/h)
- ✅ UNIT-TRIP-005: Speed with fractional hours
- ✅ UNIT-TRIP-006: Unrealistic speed detection (>120 km/h)
- ✅ UNIT-TRIP-007: Distance rounding to 2 decimals
- ✅ UNIT-TRIP-008: Negative duration handling
- ✅ UNIT-TRIP-009: Multi-waypoint distance

---

## B. FEATURE TEST

### 1. Model CRUD Test
Total **2 model files** dengan **11 test cases**

| Model | File | Tests | Status |
|-------|------|-------|--------|
| Donation | `test/feature/donation_model_feature_test.dart` | 6 | ✅ PASS |
| User Profile | `test/feature/user_model_feature_test.dart` | 5 | ✅ PASS |

#### Donation Model Tests:
- ✅ FEATURE-MODEL-001: CREATE from JSON
- ✅ FEATURE-MODEL-002: READ properties
- ✅ FEATURE-MODEL-003: UPDATE status (copyWith)
- ✅ FEATURE-MODEL-004: DELETE handling (null check)
- ✅ FEATURE-MODEL-005: Formatted values (currency, carbon)
- ✅ FEATURE-MODEL-006: toJson conversion

#### User Profile Model Tests:
- ✅ FEATURE-USER-001: CREATE from JSON
- ✅ FEATURE-USER-002: READ all properties
- ✅ FEATURE-USER-003: UPDATE profile data
- ✅ FEATURE-USER-004: DELETE handling
- ✅ FEATURE-USER-005: Required fields validation

### 2. API Controller Test
**File**: `test/feature/donation_api_test.dart`  
**Total**: 8 endpoint tests

| Test | Endpoint | Expected Status | Status |
|------|----------|----------------|--------|
| API-001 | GET /donations | 200 OK | ✅ Created |
| API-002 | GET /donations/{id} | 200 OK | ✅ Created |
| API-003 | POST /donations | 201 Created | ✅ Created |
| API-004 | PATCH /donations/{id} | 200/204 OK | ✅ Created |
| API-005 | DELETE /donations/{id} | 204 No Content | ✅ Created |
| API-006 | POST /donations (invalid) | 400 Bad Request | ✅ Created |
| API-007 | GET /donations/{invalid} | 404 Not Found | ✅ Created |
| API-008 | GET /donations (no auth) | 401 Unauthorized | ✅ Created |

**Note**: API tests use `skip: true` by default dan memerlukan authentication real untuk di-run.

---

## C. ASSERTION METHODS

### 1. PHPUnit-style Assertions
**File**: `test/assertion_examples/phpunit_style_test.dart`  
**Total**: 7 assertion types + 2 use cases

| Laravel/PHPUnit | Dart/Flutter | Example |
|-----------------|--------------|---------|
| `assertEquals($a, $b)` | `expect(actual, equals(expected))` | ✅ Implemented |
| `assertTrue($condition)` | `expect(condition, isTrue)` | ✅ Implemented |
| `assertFalse($condition)` | `expect(condition, isFalse)` | ✅ Implemented |
| `assertNull($value)` | `expect(value, isNull)` | ✅ Implemented |
| `assertNotNull($value)` | `expect(value, isNotNull)` | ✅ Implemented |
| `assertCount($n, $array)` | `expect(list, hasLength(n))` | ✅ Implemented |

**Penjelasan Assertion**:
- **assertEquals**: Membandingkan dua nilai apakah sama
- **assertTrue**: Memverifikasi kondisi bernilai true
- **assertFalse**: Memverifikasi kondisi bernilai false
- **assertNull**: Memastikan nilai adalah null
- **assertNotNull**: Memastikan nilai bukan null
- **assertCount**: Menghitung jumlah elemen dalam collection

### 2. Database Assertions
**File**: `test/assertion_examples/database_assertions_test.dart`  
**Total**: 3 assertion types + 3 practical examples

| Laravel | Flutter/Dart | Implementation |
|---------|--------------|----------------|
| `assertDatabaseHas('table', [...])` | Query + `expect(results, isNotEmpty)` | ✅ Implemented |
| `assertDatabaseMissing('table', [...])` | Query + `expect(results, isEmpty)` | ✅ Implemented |
| `assertDatabaseCount('table', n)` | Query + `expect(results, hasLength(n))` | ✅ Implemented |

**Penjelasan**:
- **assertDatabaseHas**: Memverifikasi record **ada** di database dengan kriteria tertentu
- **assertDatabaseMissing**: Memverifikasi record **tidak ada** di database
- **assertDatabaseCount**: Memverifikasi jumlah record sesuai ekspektasi

### 3. HTTP Assertions
**File**: `test/assertion_examples/http_assertions_test.dart`  
**Total**: 7 HTTP assertion types + 3 practical examples

| Laravel | Dart/Flutter | Status Code |
|---------|--------------|-------------|
| `assertStatus(200)` | `expect(statusCode, equals(200))` | ✅ Implemented |
| `assertOk()` | `expect(statusCode, equals(200))` | ✅ Implemented |
| `assertCreated()` | `expect(statusCode, equals(201))` | ✅ Implemented |
| `assertNotFound()` | `expect(statusCode, equals(404))` | ✅ Implemented |
| `assertJsonCount(n)` | `expect(jsonArray, hasLength(n))` | ✅ Implemented |
| `assertJson([...])` | `expect(json['key'], equals(value))` | ✅ Implemented |
| `assertJsonValidationErrors([...])` | `expect(json['errors'], containsKey)` | ✅ Implemented |

**Penjelasan**:
- **assertStatus**: Memverifikasi HTTP status code spesifik
- **assertOk**: Shorthand untuk status 200 OK
- **assertCreated**: Memverifikasi resource dibuat (201)
- **assertNotFound**: Memverifikasi resource tidak ditemukan (404)
- **assertJsonCount**: Menghitung item dalam JSON array
- **assertJson**: Memverifikasi struktur dan nilai JSON
- **assertJsonValidationErrors**: Memverifikasi error validation ada

---

## SUMMARY

### Total Test Coverage

| Category | Files | Test Cases | Status |
|----------|-------|------------|--------|
| **Unit Tests** | 5 | 41 | ✅ 41/41 PASS |
| **Feature Tests (Model)** | 2 | 11 | ✅ 11/11 PASS |
| **Feature Tests (API)** | 1 | 8 | ✅ Created |
| **Assertion Examples** | 3 | 20+ | ✅ Created |
| **TOTAL** | **11 files** | **80+ tests** | **✅ Complete** |

### Command untuk Menjalankan Test

```bash
# Semua unit tests
flutter test test/unit/

# Semua feature tests
flutter test test/feature/

# Semua assertion examples
flutter test test/assertion_examples/

# Semua tests sekaligus
flutter test

# Dengan coverage
flutter test --coverage
```

### Struktur File Testing

```
test/
├── unit/                                    # 5 files, 41 tests
│   ├── auth_service_test.dart
│   ├── emission_calculation_test.dart
│   ├── donation_validation_test.dart
│   ├── profile_validation_test.dart
│   └── trip_calculation_test.dart
├── feature/                                 # 3 files, 19 tests
│   ├── donation_model_feature_test.dart
│   ├── user_model_feature_test.dart
│   └── donation_api_test.dart
└── assertion_examples/                      # 3 files, 20+ examples
    ├── phpunit_style_test.dart
    ├── database_assertions_test.dart
    └── http_assertions_test.dart
```

---

## KESIMPULAN

✅ **Semua requirement terpenuhi**:
1. ✅ Unit Test: 5 service (41 tests)
2. ✅ Feature Test: Model CRUD (11 tests) + API 8 endpoints
3. ✅ Assertion Methods: 3 jenis (PHPUnit, Database, HTTP)

**Framework yang digunakan**:
- Flutter/Dart sebagai pengganti PHP/Laravel
- flutter_test sebagai pengganti PHPUnit
- Supabase queries sebagai pengganti Eloquent
- http package untuk HTTP testing

**Kualitas Test**:
- Test coverage komprehensif untuk semua fitur utama
- Assertion jelas dan terdokumentasi
- Mapping Laravel → Flutter lengkap
- Siap untuk dokumentasi akademik dengan screenshot

---

**Dibuat oleh**: EcoTrack Development Team  
**Tanggal**: 16 Desember 2024  
**Versi**: 1.0
