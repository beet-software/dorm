# dorm_firebase_database example

An example app to demonstrate how to initialize and use dORM with Firebase Realtime Database.

Explore the example project! Check out

- *pubspec.yaml* to see what dependencies are required for dORM to work
- *lib/models.dart* to have an insight on how to declare your model classes
- *lib/main.dart* to learn how to use it in practice in your application
- *lib/models.dorm.dart* and *lib/models.g.dart* to understand what classes are generated

## Getting started

1. Download the Firebase CLI
from [the official site](https://firebase.google.com/docs/cli?install_the_firebase_cli).

2. It requires at least Java 11, which you can download
from [the official site](https://www.oracle.com/br/java/technologies/javase/jdk11-archive-downloads.html).

3. Clone this repository:

    ```shell
    git clone https://github.com/enzo-santos/dorm.git
    cd dorm/dorm_firebase_database/example
    ```

## Usage

1. Run the following line in your command prompt:

    ```shell
    firebase init
    ```

    - For "You're about to initialize a Firebase project in this directory. Are you ready to proceed?",
      answer *Yes*.
    - For "Which Firebase features do you want to set up for this directory?", select *Realtime
      Database* and *Emulators*.
    - For "Let's associate this project directory with a Firebase project", select *Don't set up a
      default project*
    - For "What file should be used for Realtime Database Security Rules?", answer
      *database.rules.json* (the default)
    - For "Which Firebase emulators do you want to set up?", select *Database Emulator*
    - For "Which port do you want to use for the database emulator?", answer *9000* (the default)
    - For "Would you like to enable the Emulator UI?", answer as you like
    - For "Would you like to download the emulators now?", answer *Yes*

2. Activate the emulator by running the following command:

    ```cmd
    firebase emulators:start --only database
    ```

    Wait for the "All emulators ready! It is now safe to connect your app" message.

3. Install the dependencies, generate the dORM code and run the application:

    ```shell
    flutter pub get
    flutter pub run build_runner build
    flutter run
    ```
