# dORM example

A full Flutter application using dORM.

## Getting started

Clone this repository:

```shell
git clone https://github.com/enzo-santos/dorm.git
cd dorm/dorm/example
```

If you want a local Firebase instance, run the following line in your command prompt:

```shell
firebase init
```

- For "You're about to initialize a Firebase project in this directory. Are you ready to proceed?",
  enter *Y*.
- For "Which Firebase features do you want to set up for this directory?", only select *Emulators*.
- For "Let's associate this project directory with a Firebase project", select *Don't set up a
  default project*.
- For "Which Firebase emulators do you want to set up?", only select *Database Emulator*.
- For "Which port do you want to use for the database emulator?", leave the default (9000).
- For "Would you like to enable the Emulator UI?", enter *Y* or *n*.
    - If you entered *Y*, for "Which port do you want to use for the Emulator UI?", leave empty.
- For "Would you like to download the emulators now?", enter *Y*.

Wait for the message "Firebase initialization complete" to show up.

Run the emulator:

```shell
firebase emulators:start --only database
```

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

The user should be able to

1. retrieve user information, including their associated orders and profile details.
2. get all products in an order, along with their quantities.
3. fetch all orders placed by a specific user.
4. find the total number of orders.
5. get the average rating for a product based on reviews.
6. search for reviews of a particular type and filter them based on review content attributes.
7. get the most recent orders placed.
8. find products with a specific price range.
9. retrieve the user who placed a particular order.
10. search for orders containing specific products.

## Implementation

The screens are available on *lib/screens/*.

- The `UsersScreen` (*users.dart*) can be used to see all the users or add an user to the system.
    - Uses `pullAll` to read all users from the system, given a name (filter by text)
    - Uses `put` to create a new row on the `users` table (creating a strong entity)

- The `UserScreen` (*user.dart*) can be used to update an user and view its cart, if created.
    - Uses `pull` to read a specific row on the `users` and `carts` table (one-to-one relationship)
    - Uses `push` and `pop` to edit and remove a specific row on the `users` table, respectively
    - Uses `put` to create a new row on the `carts` table (creating a weak entity)

- The `CartScreen` (*cart.dart*) can be used to see the products placed in its cart by an user.
    - Uses `pullAll` to read all items of a specific cart (filter by value)
    - Uses `OneToOneRelationship` to associate items with their respective products
    - Uses `put` to create a new row on the `order-items` table (creating a weak entity)

- The `OrderScreen` (*order.dart*) can be used to select a product and its amount to be added to a cart.
    - Uses `pullAll` to read all products from the system (no filter)
    - Uses `push` and `pop` to edit and remove a specific row on the `products` table, respectively
    - User `put` to create a new row on the `products` table (creating a strong entity)
