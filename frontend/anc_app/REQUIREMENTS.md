## Requirements
The goal of this exercise is to implement a simple app that allows users to sign in, sign up, and manage their TODO items. All features will be mocked.

A successful implementation should meet the following requirements:
- Follows the current code structure.
- Uses BLoC for state management in the way that it's currently being used.
- Uses the current routing system.
- Follows the current onion-like architecture with feature-based scaffolding
- Has basic UX considerations.

### 1. Implement authentication
Implement the sign in and sign up screens (email/password, and name) using the provided mocks (see `lib/src/features/auth). Stick to the current code structure and use the provided Cubit for the authentication feature.

### 2. Persist authentication data
We want to use shared preferences for storing user information. Your task is to implement all the current authentication use cases using SharedPreferences as the storage, while keeping all the current code untouched. You may add new files/code as needed. The goal is to implement this feature with minimal impact on the rest of the code.

### 3. Implement a TODO screen
Implement a TODO feature that allows the user to:
- Add a TODO item.
- Mark a TODO item as done.
- Delete a TODO item.

A user can only interact with their own TODO items.

All TODOs should be stored in shared preferences.

### 4. Answer the following questions once you have completed the implementation from previous steps
1. What happens if the user has 10k TODO items?
2. What happens if the app is offline?