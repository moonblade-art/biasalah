# Design Document

## Overview

This design addresses critical compilation errors in the EcoTrack Flutter application by standardizing model naming conventions, fixing property access issues, and ensuring consistent type usage across services and UI components. The solution focuses on minimal changes that restore compilation while maintaining existing functionality.

## Architecture

The fix involves three main architectural components:

1. **Model Layer Standardization**: Align notification model naming between definition and usage
2. **Service Layer Property Access**: Fix Supabase client property access in services
3. **Type System Consistency**: Ensure all type annotations match actual class definitions

## Components and Interfaces

### Notification System Components

**NotificationMessage → AppNotification Alignment**
- The existing `NotificationMessage` class will be aliased or renamed to `AppNotification`
- All service references will use the consistent `AppNotification` type
- Import statements will be updated to reference the correct model

**NotificationService Interface**
```dart
class NotificationService {
  Future<List<AppNotification>> getUserNotifications({...});
  Future<AppNotification> createNotification({...});
  Future<AppNotification> markAsRead(String notificationId);
}
```

### Donation Service Components

**SupabaseClient Property Access**
- Replace invalid `supabaseKey` property access with correct Supabase client API
- Fix `_functionsUrl` property access with proper URL construction
- Ensure authentication token access uses valid session properties

**DonationService Interface**
```dart
class DonationService {
  Future<Map<String, dynamic>> checkPaymentStatus(String orderId);
  Future<Map<String, dynamic>> testConnection();
}
```

## Data Models

### AppNotification Model
```dart
class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  
  AppNotification copyWith({...});
  factory AppNotification.fromJson(Map<String, dynamic> json);
}
```

### NotificationPreferences Model
```dart
class NotificationPreferences {
  final String id;
  final String userId;
  final bool tripNotifications;
  final bool donationNotifications;
  // ... other preference fields
}
```

## C
orrectness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Property 1: Notification type consistency
*For any* notification service method that references AppNotification, the system should use the same class definition consistently across all method signatures and implementations
**Validates: Requirements 1.1**

Property 2: Notification method return type consistency  
*For any* notification service method that returns notification instances, the returned objects should match the declared return type annotations
**Validates: Requirements 1.3**

Property 3: Notification list type safety
*For any* operation on notification lists, all elements should maintain the correct AppNotification type throughout the processing chain
**Validates: Requirements 1.4**

Property 4: Notification object instantiation consistency
*For any* notification object creation, the system should use valid constructors and factory methods that exist on the AppNotification class
**Validates: Requirements 1.5**

Property 5: Supabase property access validity
*For any* DonationService method that accesses Supabase client properties, the property names should exist and be accessible on the SupabaseClient class
**Validates: Requirements 2.1**

Property 6: HTTP request construction validity
*For any* payment status check operation, the HTTP requests should have valid URLs, proper headers, and correct authentication tokens
**Validates: Requirements 2.2**

Property 7: Authentication property access validity
*For any* Supabase authentication operation, the system should access authentication properties through valid session methods and properties
**Validates: Requirements 2.3**

Property 8: Edge Function URL construction validity
*For any* Edge Function call, the URL construction should use valid methods and properties available on the Supabase client
**Validates: Requirements 2.4**

Property 9: API key access validity
*For any* operation requiring API keys, the system should access them through valid client interface methods and properties
**Validates: Requirements 2.5**

Property 10: Method parameter compatibility
*For any* notification method call, the parameters should match the expected method signatures and types
**Validates: Requirements 4.1**

Property 11: Model method availability
*For any* model method invocation like copyWith, the method should exist on the correct class and execute successfully
**Validates: Requirements 4.2**

Property 12: Property getter accessibility
*For any* property getter access on objects, the getters should exist on the appropriate object types and return expected values
**Validates: Requirements 4.3**

Property 13: Service return type consistency
*For any* service method execution, the returned values should match the declared return types
**Validates: Requirements 4.4**

Property 14: Async operation type handling
*For any* asynchronous operation, the Future types should be handled correctly and return the expected types upon completion
**Validates: Requirements 4.5**

## Error Handling

### Compilation Error Prevention
- All type references must resolve to existing classes
- All property accesses must use valid property names
- All method calls must match existing method signatures
- All import statements must reference existing files

### Runtime Error Handling
- Service methods should handle invalid property access gracefully
- Model instantiation should validate constructor parameters
- HTTP requests should handle authentication failures
- Async operations should handle Future completion errors

### Fallback Mechanisms
- If AppNotification class is missing, create it from NotificationMessage
- If Supabase properties are invalid, use alternative access methods
- If method signatures don't match, update call sites to match definitions
- If imports fail, update file paths to correct locations

## Testing Strategy

### Unit Testing Approach
- Test individual service methods for correct return types
- Test model instantiation with various parameter combinations
- Test property access on Supabase client objects
- Test HTTP request construction with different authentication states

### Property-Based Testing Approach
- Use **fast_check** library for Dart property-based testing
- Configure each property-based test to run a minimum of 100 iterations
- Each property-based test will be tagged with comments referencing the design document properties

**Property-based testing requirements:**
- Generate random notification data and verify type consistency
- Generate random service call parameters and verify method compatibility
- Generate random Supabase client states and verify property access
- Generate random HTTP request scenarios and verify construction validity

**Unit testing requirements:**
- Test specific examples of notification model usage
- Test specific Supabase client property access scenarios
- Test specific HTTP request construction cases
- Test integration between notification service and UI components

Together, unit tests and property tests provide comprehensive coverage: unit tests catch concrete bugs in specific scenarios, while property tests verify general correctness across all possible inputs.