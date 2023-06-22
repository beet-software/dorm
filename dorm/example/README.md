# dORM example

A full Flutter application using dORM.

This example helps you to understand how to integrate dORM within your application using an
e-commerce code sample. It contains CRUDs, joins and some commonly used database filters, such as by
text, by value and by range.

It also shows how to integrate dORM models with forms, using
the [`flutter_form_bloc` package](https://pub.dev/packages/flutter_form_bloc).

## Getting started

1. Clone this repository:

   ```shell
   git clone https://github.com/enzo-santos/dorm.git
   cd dorm/dorm/example
   ```

2. *(optional)* If you want a local Firebase instance, run the following line in your command prompt:

   ```shell
   firebase emulators:start --only database --project react-native-firebase-testing
   ```

   The command above can be run verbatim, since `react-native-firebase-testing` is generally used as a
   dummy project ID. If you already have a project you want to integrate dORM, replace it with your own
   project's ID.

   Wait for the message "All emulators ready! It is now safe to connect your app" to show up.

3. Get the dependencies and run the application:

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

## Usage

The first screen manages all users in the system. Tap the icon on the bottom right corner to add a new user:

<div>
  <img src="https://i.imgur.com/MVxWGH0.png" style="height: 400px"/>
  <img src="https://i.imgur.com/wtkpqYU.png" style="height: 400px"/>
  <img src="https://i.imgur.com/V7lSsFK.png" style="height: 400px"/>
</div>

After you add a couple of users, you can search them by username:

<div>
  <img src="https://i.imgur.com/47h2z3M.png" style="height: 400px"/>
  <img src="https://i.imgur.com/hS9JBJB.png" style="height: 400px"/>
  <img src="https://i.imgur.com/VssRAQ4.png" style="height: 400px"/>
</div>

You can tap on a user to view, edit or delete its profile:

<div>
  <img src="https://i.imgur.com/HkdW6BN.png" style="height: 400px"/>
  <img src="https://i.imgur.com/uAowC0K.png" style="height: 400px"/>
  <img src="https://i.imgur.com/mS1E9kc.png" style="height: 400px"/>
</div>

Each user has a single cart, which you can access on its respective tile:

<div>
  <img src="https://i.imgur.com/HkdW6BN.png" style="height: 400px"/>
  <img src="https://i.imgur.com/7IIbrZq.png" style="height: 400px"/>
  <img src="https://i.imgur.com/c0rFnsE.png" style="height: 400px"/>
</div>

Tap the icon on the bottom right corner to add a new order to this user's cart:

<div>
  <img src="https://i.imgur.com/7IIbrZq.png" style="height: 400px"/>
  <img src="https://i.imgur.com/c0rFnsE.png" style="height: 400px"/>
  <img src="https://i.imgur.com/ZJcbtjY.png" style="height: 400px"/>
</div>

There won't be any products registered yet. Tap the icon on the top right corner to
enable editing mode in this screen, where you can create, edit or delete products.
When done editing, tap the icon again to reenable selection mode:

<div>
  <img src="https://i.imgur.com/c0rFnsE.png" style="height: 400px"/>
  <img src="https://i.imgur.com/ZJcbtjY.png" style="height: 400px"/>
  <img src="https://i.imgur.com/R9gicQZ.png" style="height: 400px"/>
</div>

When on editing mode, tap the icon on the bottom right corner to add a new product:

<div>
  <img src="https://i.imgur.com/R9gicQZ.png" style="height: 400px"/>
  <img src="https://i.imgur.com/6LGp0Gi.png" style="height: 400px"/>
  <img src="https://i.imgur.com/6Sq61Dz.png" style="height: 400px"/>
</div>

Add a couple of products. You can edit or remove them:

<div>
  <img src="https://i.imgur.com/kmu9FHK.png" style="height: 400px"/>
  <img src="https://i.imgur.com/mT5o7EY.png" style="height: 400px"/>
  <img src="https://i.imgur.com/BMsF4gR.png" style="height: 400px"/>
</div>

When you reenable selection mode, you'll be able to select a product and its amount:

<div>
  <img src="https://i.imgur.com/Ji8GQ0k.png" style="height: 400px"/>
  <img src="https://i.imgur.com/7BW2GYi.png" style="height: 400px"/>
  <img src="https://i.imgur.com/uAfuwxR.png" style="height: 400px"/>
</div>

When selecting a couple of products and their respective amounts, go to the main screen and
tap the button on the top right corner. This is the dashboard, and you can see the products ordered
by each user, as well as how many products each user has ordered:

<div>
  <img src="https://i.imgur.com/47h2z3M.png" style="height: 400px"/>
  <img src="https://i.imgur.com/1VaTIqR.png" style="height: 400px"/>
  <img src="https://i.imgur.com/UPmTw6i.png" style="height: 400px"/>
</div>

## Tips

- Prefer using `pull` and `pullAll` instead of `peek` and `peekAll`, since their stream will
  synchronize updates made on the model by other parts of the application.
- Use the `*Data` version of a dORM model when creating it from a form.
- Don't pass a `*Model` as argument to a new screen. Instead, pass its ID and read it again.

