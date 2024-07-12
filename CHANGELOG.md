# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `sort` extension method to `Filter`

### Changed

- `Filter` is now `BaseFilter<Q extends BaseQuery<Q>>` and has better API


## 1.0.0-alpha.6 - 2023-09-11

### Added

- List support to `ModelField`s
- Add support to sealed classes on polymorphic models


## 1.0.0-alpha.5 - 2023-07-16

### Added

- `BaseEngine` and `BaseRelationship` to `dorm_framework`
- `relationships` field to `DatabaseEntity` on `dorm_framework`

### Changed

- Relationships are now created using the `relationships` field available on `DatabaseEntity`
- Generated `Dorm` class now receives a `BaseEngine` instead of `BaseReference`

### Removed

- `OneToOneRelationship`, `OneToManyRelationship`, `ManyToOneRelationship` and 
  `ManyToManyRelationship`. Replaced by `relationships` field available on `DatabaseEntity`


## 1.0.0-alpha.4 - 2023-06-26

### Added

- Documentation

### Fixed

- Offline support for `dorm_firebase_database`


## 1.0.0-alpha.3 - 2023-06-26

### Changed

- `dorm` package now is `dorm_framework`. Change your *pubspec.yaml* and import directives.


## 1.0.0-alpha.2 - 2023-06-26

### Added

- `ManyToManyRelationship` class, supporting many-to-many joins
