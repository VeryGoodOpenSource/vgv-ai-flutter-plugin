---
title: State Handling
description: Recommended practices for handling state that are emitted from blocs/cubits.
---

To `enum` or to `sealed class`? That is the question we'll be discussing in this episode of **Very Good Engineering** 🦄, to understand which way to go when declaring states for our Cubits/Blocs.

> 💡 Either one of these options could be the right one depending on the following use cases.

## Do I want to persist previous data when emitting a new state?

As it happens when filling out a form where data is updated step by step, or when the state has several values that are loaded independently, if your aim is to update new fields of the state or the state itself without losing previously emitted data, using **a single class with an enum as the state's 'status'** it's the easiest way to go.

> 💡 You can also share properties throughout all the states by setting those inside the parent `sealed` or `abstract` class.

This can look something like:

```txt
initial state
        |----> update property 1
            |----> update property 2
                  |----> update property 3
                        |----> submit form
                                  |----> success state
                                  |----> failure state
```

Let's see an example:

```dart
enum CreateAccountStatus {
  initial,
  loading,
  success,
  failure,
}

class CreateAccountState extends Equatable {
  const CreateAccountState({
    this.status = CreateAccountStatus.initial,
    this.name,
    this.surname,
    this.email,
  });

  final CreateAccountStatus status;
  final String? name;
  final String? surname;
  final String? email;

  CreateAccountState copyWith({
    CreateAccountStatus? status,
    String? name,
    String? surname,
    String? email,
  }) {
    return CreateAccountState(
      status: status ?? this.status,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
    );
  }

  // Getter to check whether every field has valid data.
  bool get isValid => name.isNotNullOrEmpty
      && surname.isNotNullOrEmpty
      && email.isNotNullOrEmpty
      && email.isValid;

  @override
  List<Object> get props => [
    status,
    name,
    surname,
    email,
  ];
}
```

As you can see above, because the user is going to fill out their name, surname, and email, and any of them can be null or empty at any time, we need to make sure we have data in each property as per our business logic before allowing the user to create their account.

> 💡 Using `enums` to handle status is useful in cases like this where there are **several steps** for the user to fill up information and the **data emitted in previous steps should not be lost in newer emits**.

Take a look at the `Cubit` example for this implementation:

```dart

class CreateAccountCubit extends Cubit<CreateAccountState> {
  CreateAccountCubit(): super(const CreateAccountState());

  void updateName(String name) {
    // We emit the name without losing any other data.
    emit(state.copyWith(name: name));
  }

  void updateSurname(String surname) {
    // We emit the surname without losing any other data.
    emit(state.copyWith(surname: surname));
  }

  void updateEmail(String email) {
    // We emit the email without losing any other data.
    emit(state.copyWith(email: email));
  }

  // ... other update methods here.

  Future<void> createAccount() async {
    emit(state.copyWith(status: CreateAccountStatus.loading));
    try {
      // Double check the current state is valid.
      if (state.isValid) {
        emit(state.copyWith(status: CreateAccountStatus.success));
      } else {
        emit(state.copyWith(status: CreateAccountStatus.failure));
      }
    } catch (e, s) {
      addError(e, s);
      // We can emit the failure without losing the content that
      // was added by the user.
      emit(state.copyWith(status: CreateAccountStatus.failure));
    }
  }
}
```

As you can see, having a **single state class** with an `enum` for the status helps to keep the information that was added previously.

Let's see how we consume these types of states in the UI using the `BlocListener` widget.

```dart
class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BlocListener<CreateAccountCubit, CreateAccountState>(
        listener: (context, state) {
          // This is how we check for the actual status.
          if (state.status == CreateAccountStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Something went wrong')));
          }
          if (state.status == CreateAccountStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Account created!')));
          }
        },
        child: CreateAccountFormView(),
      ),
    );
  }
}
```

As seen above, with this approach, the current status comes from the `status` **enum** property inside the `cubit state`.

Let's now check the other way to handle states.

## Do I want to emit a _fresh_ state every time?

The other side of the state management aims for clean state updates, isolating the properties of each state that's emitted. This is useful for when the data being fetched is not going to change, or for instance, we don't need to keep it in future emits, and it's a matter of simply:

```txt
loading ---->   <try fetch data>    |----> success (data fetched)
                                    |----> failure
```

This can be achieved by leveraging the use of `sealed classes` (when in Flutter `3.13+`) or basic `abstract classes` (when in older Flutter versions).

### Using `sealed` classes

Let's see how the states are built:

```dart
// Using sealed classes.
sealed class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  ProfileSuccess(this.profile);

  final Profile profile;
}

class ProfileFailure extends ProfileState {
  ProfileFailure(this.errorMessage);

  final String errorMessage;
}
```

As you can see, each state holds its own data, and it's properly isolated from one another.

Let's now see how to treat this state in the Cubit:

```dart
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading()) {
    getProfileDetails();
  }

  Future<void> getProfileDetails() async {
    try {
      await Future.delayed(const Duration(seconds: 3), () {});

      final data = Profile(
        name: 'Pepe',
        surname: 'Martinez',
        email: 'pepe@gmail.com',
      );

      emit(ProfileSuccess(data));
    } catch (e) {
      // We can emit the failure without losing the content that was
      // added by the user.
      emit(ProfileFailure(
          'Oops, could not load your profile. Please try again later.'));
    }
  }
}
```

And now let's consume that `Cubit` from the UI:

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(builder: (context, state) {
        // Leverage the usage of switch statements.
        return switch (state) {
          ProfileLoading() => const _ProgressIndicator(),
          // 'success' here is the same state value casted as a ProfileSuccess.
          ProfileSuccess success => ProfileView(success.profile),
          // Here we get the message property from the ProfileFailure state.
          ProfileFailure(errorMessage: final message) => Text(message),
        };
      }),
    );
  }
}
```

As you can see, `sealed classes` helps us to properly **isolate** data inside each state, and whenever we check we are in a certain state **we are sure that the data won't be null at all**, as it happens when dealing with `enum states`.

### Using `abstract` classes

```dart
// Using abstract classes.
abstract class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  ProfileSuccess(this.profile);

  final Profile profile;
}

class ProfileFailure extends ProfileState {
  ProfileFailure(this.errorMessage);

  final String errorMessage;
}
```

The `Cubit` class doesn't change at all:

```dart
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading()) {
    getProfileDetails();
  }

  Future<void> getProfileDetails() async {
    try {
      await Future.delayed(const Duration(seconds: 3), () {});

      final data = Profile(
        name: 'Pepe',
        surname: 'Martinez',
        email: 'pepe@gmail.com',
      );

      emit(ProfileSuccess(data));
    } catch (e) {
      // We can emit the failure without losing the content that was
      // added by the user.
      emit(ProfileFailure(
          'Oops, could not load your profile. Please try again later.'));
    }
  }
}
```

But the way we consume **states** as `classes` differs:

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (_, state) {
          // Using normal Switch statement.
          switch (state) {
            case ProfileLoading():
              return const _ProgressIndicator();
            case ProfileSuccess():
              // Properties have to be accessed by the state.
              return ProfileView(state.profile);
            case ProfileFailure():
              return Text(state.errorMessage);
            // Default case is mandatory.
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
```

Here you can see that consuming states based on an `abstract class` is more painful than using `sealed classes`, but is still the way to go when the Flutter version is not up-to date and you would like to isolate each state.

### Bonus - Share properties in some of the states (sealed or abstract classes)

You might be wondering... can I have the same property in more than one state and still continue to use sealed classes? **Yes you can!**

> 💡 You can also share properties throughout all the states by setting those inside the parent `sealed` or `abstract` class.

Let's look at an updated version of our state and cubit implementation using `sealed classes` (Pst! Same thing works for `abstract classes` as well):

```dart
sealed class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  ProfileSuccess(this.profile);

  final Profile profile;
}

class ProfileEditing extends ProfileState {
  ProfileEditing(this.profile);

  final Profile profile;
}

class ProfileFailure extends ProfileState {
  ProfileFailure(this.errorMessage);

  final String errorMessage;
}
```

As seen above, `ProfileSuccess` and `ProfileEditing` contains a `Profile` property inside. How can we handle that from inside the `Cubit`?

```dart
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading()) {
    getProfileDetails();
  }

  Future<void> getProfileDetails() async {
    // Already seen.
  }

  Future<void> editName(String newName) async {
    switch(state) {
      // Here we get both Profile objects stored inside each state class
      // and we're able to use it inside the block to update the profile.
      case ProfileSuccess(profile: final prof):
      case ProfileEditing(profile: final prof):
        final newProfile = prof.copyWith(name: newName);
        emit(ProfileSuccess(newProfile));
      case ProfileLoading():
      case ProfileFailure():
        return;
    }
  }
}
```

This way you can be sure to handle all states in your Cubit methods and also be able to use the values contained.

To conclude this part, here's also the way to do the same thing but UI side:

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(builder: (context, state) {
        // Leverage the usage of switch statements.
        return switch (state) {
          ProfileLoading() => const _ProgressIndicator(),
          // We get the Profile prof by declaring a value based on the
          // internal property of the state.
          ProfileSuccess(profile: final prof)
          || ProfileEditing(profile: final prof) => ProfileView(prof),
          // Here we get the message property from the ProfileFailure state.
          ProfileFailure(errorMessage: var message) => Text(message),
        };
      }),
    );
  }
}
```

Hope this helps to get an idea about which route to take when designing states for your Cubits/Blocs.✨
