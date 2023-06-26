# dORM

A language-agnostic Object Relational Mapper library for Dart.

This ORM uses separation of concerns as the main concept of its framework: 

- The **model** (*what* to manipulate) represents the database schema. If you have an UML diagram
  of your database, containing the tables, columns and relationships, you can represent it the framework.
- The **engine** (*where* to manipulate) represents the database driver. You can implement your custom
  database engine to work with dORM without affecting your schema or your controller.
- The **controller** (*how* to manipulate) represents the database operations. This is where you
  create, read, update and delete the models of your database.

![](https://i.imgur.com/fBpjhA5.png)

## Getting started

Inside a Dart (or Flutter) project, run the following lines in your command prompt:

```shell
dart pub add dorm
dart pub add dorm_annotations
dart pub add dev:dorm_generator
dart pub add dev:build_runner
# Choose a dorm_*_database package to use as engine
dart pub add dorm_firebase_database
dart pub get
```

Take a look at the chosen `dorm_*_database` package to learn how to set it up.

## Usage

dORM works based on code generation. Take a look at the `dorm_annotations` and `dorm_generator` packages
(in this order) to learn how to annotate your code, discover what annotations are available to you and 
run the generator to create your *.dorm.dart* and *.g.dart* files.

This is a flowchart for code generation exposed by this package:

![](https://i.imgur.com/necLoxW.png)

In the left frame, there should be a source-code equivalent of your database schema. Every class annotated
with `Model` represents a database table and every getter annotated with `Field` represents a database column.
In this step, you should not worry about the database engine settings, this is *only* model setup.

After annotating your code, run the following in your command prompt:

```shell
dart pub run build_runner build
``` 

This will create a *.dorm.dart* file (shown in the right frame) and a *.g.dart* file. Don't worry about the
generated code for now. If you want to learn more about it, take a look at the `dorm` package. What you need
to know is that there will be a generated class named `Dorm`. For every model you set up, a field will be
added to this class, allowing you to manipulate the database (such as creating, reading, updating and deleting)
based on each table.

However, `Dorm` accepts a `BaseReference` as an argument on its constructor. In this step, you must select
a `dorm_*_database` to use as your database engine. This library exports some engines as default, such as `firebase`
and `bloc`, but you can implement your own if you want (read more below). Every `dorm_*_database` exports a
`Reference` class, which inherits from `BaseReference` and you can pass to the generated `Dorm` class.

This is a flowchart explaining this procedure:

![](https://i.imgur.com/mh2v9eV.png)

The frame on the right represents your application code, ready to use dORM.

### Examples

On the *dorm/example* directory, there is a complete Flutter application integrated with dORM, using a lot of 
features for you to understand better how this package works.

## Documentation

dORM is a framework with a lot of features, so before diving into it, read the vast documentation and its well-crafted
examples.  

Here's a step-by-step guide:

1. Represent your database schema as source code, explained by `dorm_annotations`
2. Fit your schema into dORM's framework, explained by `dorm_generator`
3. Manipulate the generated code using filters and joins, explained by `dorm`
4. Discover what database engines are available to integrate with dORM
   - Integrate using Firebase Realtime Database, explained by `dorm_firebase_database`
   - Integrate using local memory and the BLoC pattern, explained by `dorm_bloc_database`
   - Your app uses another engine? Take a look at the "Implementing your own engine" section below

You can find an *example/* folder inside *every* package mentioned above, containing specific examples
on how to use them. Note that you will not learn the framework just by reading this document or exploring
just one of the packages above. Each documentation complements the other.

## Disclaimers

dORM does not yet handle

- transactions
- paginations

These features may be supported in future releases.

## Implementing your own engine

If you want to implement a new database engine for dORM, you can look at `dorm_bloc_database`
and `dorm_firebase_database` as a base to learn how to implement your own driver, such as MySQL or MongoDB.

Basically,

1. Create a new Dart package.

   ```shell
   dart create -t package dorm_<DRIVER>_database
   cd dorm_<DRIVER>_database
   ```

2. Add `dorm` as dependency of your package:

   ```shell
   dart pub add dorm
   # Optionally, add lints to your project
   dart pub add dev:lints
   ```

3. Make a directory at *lib/src* and create two files: *query.dart* and *reference.dart*.
4. Inside *query.dart*, add the following contents:

   ```dart
   import 'package:dorm/dorm.dart';

   class Query implements BaseQuery<Query> { /* ... */ }
   ```

   As a convention, this class should be named `Query` and should be marked as constant.
   Add an object as a field of this class such that your database package can handle queries
   using it. Accept this field as a parameter in the constructor of this class:

   ```dart
   import 'package:dorm/dorm.dart';

   class Query implements BaseQuery<Query> {
     final T value;

     const Query({required this.value});
   }
   ```

   For every implemented method, you should manipulate this object and create a new `Query` instance
   with that updated value. [Purely as an pseudocode](https://www.explainxkcd.com/wiki/index.php/327:_Exploits_of_a_Mom), this is a way of doing it using SQL:

   ```dart
   import 'package:dorm/dorm.dart';

   class Query implements BaseQuery<Query> {
     final String cmd;

     const Query({required this.cmd});

       @override
       Query whereValue(String key, Object? value) {
         return Query(cmd: '$cmd WHERE $key = $value');
       }
   }
   ```

   Implement every method inherited from `BaseQuery`.

5. Inside *reference.dart*, add the following contents:

   ```dart
   import 'package:dorm/dorm.dart';

   class Reference implements BaseReference { /* ... */ }
   ```

   As a convention, this class should be named `Reference` and should not necessarily be marked as constant.

   Read the docstring of the methods declared inside `BaseReference` to know how to implement each one.
   Each method receives as first parameter an `Entity`, which you can access table informations such as
   its name on the database, how to create a new model and how to (de)serialize an existing model.

7. Inside *lib/dorm_\<DRIVER\>_database.dart*, add the following contents:

   ```dart
   library dorm_DRIVER_database;

   // Add zero or more third-party exports you may find relevant 
   export 'package:foo/bar.dart';

   export 'src/query.dart';
   export 'src/reference.dart';
   ```

8. Finally, add your created package to the application you want to integrate with dORM (or make a pull request 🙂):

   ```shell
   dart pub add dorm_<DRIVER>_database
   ```
