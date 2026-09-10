# dorm_example example

`dorm_example` is a command-line generator for complete dORM showcase
projects. Install the executable and generate a project for one engine:

```shell
dart pub global activate dorm_example
dorm_example --engine memory --output memory
```

The generated directory contains annotated models, backend setup, and the
commands needed to run code generation and the showcase application. Omit
`--output` to use the selected engine name as the directory name.

See the package README and the dORM showcase guide for the supported profiles
and backend-specific setup instructions.