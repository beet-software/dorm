# dORM example

A full Flutter application using dORM.

This example helps you to understand how to integrate dORM within your application using an
e-commerce code sample. It contains CRUDs, joins and some commonly used database filters, such as by
text, by value and by range.

It also shows how to integrate dORM models with forms, using
the [`flutter_form_bloc` package](https://pub.dev/packages/flutter_form_bloc).

## Getting started

Clone this repository:

```shell
git clone https://github.com/enzo-santos/dorm.git
cd dorm/dorm/example
```

If you want a local Firebase instance, run the following line in your command prompt:

```shell
firebase emulators:start --only database --project react-native-firebase-testing
```

The command above can be run verbatim, since `react-native-firebase-testing` is generally used as a
dummy project ID. If you already have a project you want to integrate dORM, replace it with your own
project's ID.

Wait for the message "All emulators ready! It is now safe to connect your app" to show up.

## Usage

Get the dependencies and run the application:

```shell
flutter pub get
flutter run
```

## Requirements

The application shall be an e-commerce.

- An user must have an username, an email and its personal info, such as name, birthdate and an
  optional bio.
- A product must have a name, a description and a price.
- A cart must have a timestamp of when it was first created.
- A review must contain a text, the timestamp of when it was published and its content.
- Each user can have one cart at a time.
- Each cart can have infinite products (no inventory handling).
- Each product in a cart must have an amount (at least one item).
- A user can make infinite reviews.
- A user can review a product, a service or another user.

## Implementation

The screens are available on *lib/screens/*.

- The `UsersScreen` (*users.dart*) can be used to see all the users or add an user to the system.
    - Uses `pullAll` to read all users from the system, given a username (filtering by text)
    - Uses `put` to create a new user (creating a strong entity)

- The `UserScreen` (*user.dart*) can be used to update an user and view its cart, if created.
    - Uses `pull` to read this user with its cart, if exists
    - Uses `push` and `pop` to edit and remove this user, respectively
    - Uses `put` to create a new cart (creating a weak entity)
    - Uses `pullAll` to read all reviews of a given type from this user (filtering by many values)
    - Uses `pop` to remove a review

- The `CartScreen` (*cart.dart*) can be used to see the products placed in its cart by an user.
    - Uses `pullAll` to read all items of a specific cart (filtering by value)
    - Uses `OneToOneRelationship` to associate cart items with their respective products (1-to-1)
    - Uses `put` to create a new item on user's cart (creating a weak entity)

- The `OrderScreen` (*order.dart*) can be used to select a product and its amount to be added to a
  cart.
    - Uses `pullAll` to read all products from the system (without filtering)
    - Uses `push` and `pop` to edit and remove a product, respectively
    - User `put` to create a new product (creating a strong entity)

- The `DashboardScreen` (*dashboard.dart*) can be used to view some statistics about the system.
    - Uses `OneToManyRelationship` combined with `OneToOneRelationship` to list all products ordered
      by an user
    - Uses `ManyToOneRelationship` to how many users have ordered a given product

[//]: # (TODO Filter by enum)

[//]: # (TODO pullAll read all orders made in a given day)

[//]: # (TODO pullAll read all orders made in a given date range)

[//]: # (TODO pullAll read all products ordered more than 10 amounts)

## Tips

- Prefer using `pull` and `pullAll` instead of `peek` and `peekAll`, since their stream will
  synchronize updates made on the model by other parts of the application.
- Use the `*Data` version of a dORM model when creating it from a form.
- Don't pass a `*Model` as argument to a new screen. Instead, pass its ID and read it again.
