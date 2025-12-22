# 🏛️ Architecture Documentation

## Overview

This app implements **Clean Architecture** with **BLoC pattern** for state management, ensuring scalability, testability, and maintainability.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Screens   │  │   Widgets   │  │    BLoC     │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                  DOMAIN LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Entities   │  │  Use Cases  │  │ Repositories│    │
│  │             │  │             │  │(Interfaces) │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                   DATA LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Models    │  │ Data Sources│  │ Repositories│    │
│  │             │  │(Remote/Local│  │    (Impl)   │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer
**Responsibility**: UI and user interaction

**Components**:
- **Pages/Screens**: Flutter widgets representing full screens
- **Widgets**: Reusable UI components
- **BLoC**: Business Logic Components managing UI state

**Rules**:
- Can only depend on Domain layer
- Never directly access Data layer
- Handles user input and displays data
- Converts domain entities to UI models

**Example**:
```dart
// BLoC receives events, calls use cases, emits states
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  
  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    final result = await loginUseCase(event.email, event.password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }
}
```

### 2. Domain Layer
**Responsibility**: Business logic (platform-independent)

**Components**:
- **Entities**: Core business objects (User, Device, Route, etc.)
- **Use Cases**: Single-purpose business operations
- **Repository Interfaces**: Contracts for data operations

**Rules**:
- No dependencies on other layers
- Pure Dart (no Flutter dependencies)
- Contains business rules and logic
- Defines interfaces, not implementations

**Example**:
```dart
// Use Case: Single responsibility
class LoginUseCase {
  final AuthRepository repository;

  Future<Either<Failure, User>> call(String email, String password) {
    return repository.login(email, password);
  }
}

// Repository Interface (contract)
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
}
```

### 3. Data Layer
**Responsibility**: Data management and external communication

**Components**:
- **Models**: Data transfer objects (DTOs)
- **Data Sources**: Local (cache) and Remote (API, BLE, etc.)
- **Repository Implementations**: Concrete implementations of domain interfaces

**Rules**:
- Implements domain repository interfaces
- Handles data transformation (Model ↔ Entity)
- Manages multiple data sources
- Error handling and data caching

**Example**:
```dart
// Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      await localDataSource.cacheUser(userModel);
      return Right(userModel); // Model extends Entity
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
```

## Data Flow

### User Action Flow
```
User Tap Button
  ↓
Widget dispatches Event to BLoC
  ↓
BLoC calls Use Case
  ↓
Use Case calls Repository (interface)
  ↓
Repository (implementation) calls Data Source
  ↓
Data Source fetches data (API/BLE/Local)
  ↓
Data returned as Model
  ↓
Repository converts Model to Entity
  ↓
Use Case returns Entity wrapped in Either<Failure, Entity>
  ↓
BLoC processes result and emits State
  ↓
Widget rebuilds with new State
```

### Example: Login Flow

```dart
// 1. User taps login button
ElevatedButton(
  onPressed: () {
    context.read<AuthBloc>().add(
      LoginRequested(email: email, password: password)
    );
  },
)

// 2. BLoC receives event
on<LoginRequested>((event, emit) async {
  emit(AuthLoading());
  
  // 3. BLoC calls use case
  final result = await loginUseCase(event.email, event.password);
  
  // 4. BLoC processes result
  result.fold(
    (failure) => emit(AuthError(failure.message)),
    (user) => emit(Authenticated(user)),
  );
});

// 5. Widget rebuilds
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return CircularProgressIndicator();
    if (state is Authenticated) return HomePage();
    // ...
  },
)
```

## Feature Structure

Each feature follows this structure:

```
feature_name/
├── data/
│   ├── datasources/
│   │   ├── feature_local_datasource.dart
│   │   └── feature_remote_datasource.dart
│   ├── models/
│   │   └── feature_model.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       ├── usecase_1.dart
│       └── usecase_2.dart
└── presentation/
    ├── bloc/
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── pages/
    │   └── feature_page.dart
    └── widgets/
        └── feature_widget.dart
```

## Dependency Injection

Uses `get_it` for service location:

```dart
// Registration
getIt.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(getIt(), getIt()),
);

getIt.registerLazySingleton(() => LoginUseCase(getIt()));

getIt.registerFactory(() => AuthBloc(
  loginUseCase: getIt(),
  // ...
));

// Usage in widget
BlocProvider(
  create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus()),
  child: MyApp(),
)
```

## Error Handling

Uses `Either<Failure, Success>` pattern from `dartz`:

```dart
// Success path
return Right(user);

// Failure path
return Left(AuthFailure('Invalid credentials'));

// Usage
result.fold(
  (failure) => handleError(failure),
  (user) => handleSuccess(user),
);
```

## State Management with BLoC

### BLoC Pattern Benefits
- Separates business logic from UI
- Testable without UI dependencies
- Predictable state changes
- Easy debugging with BLoC observer

### BLoC Components

**Events**: User actions or system events
```dart
abstract class AuthEvent extends Equatable {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
}
```

**States**: UI representations
```dart
abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
}
class AuthError extends AuthState {
  final String message;
}
```

**BLoC**: Event handlers
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Handle event, call use cases, emit states
  }
}
```

## Testing Strategy

### Unit Tests
- Test use cases independently
- Mock repositories
- Test BLoC logic

### Integration Tests
- Test feature flows
- Mock external dependencies

### Widget Tests
- Test UI components
- Mock BLoCs

## Best Practices

1. **Single Responsibility**: Each class has one job
2. **Dependency Inversion**: Depend on abstractions, not implementations
3. **Immutability**: Use `const` and `final` wherever possible
4. **Error Handling**: Always handle errors gracefully
5. **Logging**: Use logger for debugging
6. **Code Comments**: Document complex logic
7. **Naming**: Use clear, descriptive names

## Communication Patterns

### App ↔ Smart Glasses

```
Mobile App (Flutter)
    ↓ BLE Commands
Smart Glasses (Embedded)
    ↓ Sensor Data
Mobile App processes
    ↓ AI Processing
Mobile App responds
    ↓ Voice/Audio
Smart Glasses speakers
```

### Voice Command Flow

```
User speaks → Glasses mic → 
App (speech_to_text) → 
Command parsing → 
Route to handler → 
Execute action → 
Generate response → 
TTS (flutter_tts) → 
Glasses speakers
```

## Scalability Considerations

- **Modular architecture**: Easy to add new features
- **Plugin system**: Voice command plugins
- **Microservices-ready**: Can split backend services
- **Multi-device**: Architecture supports multiple glasses
- **Offline-first**: Local caching and sync

---

This architecture ensures the app is maintainable, testable, and ready for production deployment.

