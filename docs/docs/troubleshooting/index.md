# Troubleshooting

Start with the point at which the problem appears. dORM has separate stages
for dependency resolution, code generation, Dart analysis, repository calls,
and backend execution.

| Problem | `Page` |
| --- | --- |
| A command, package, or repository call fails and the layer is unclear | [Find the failing layer](error-by-layer.md) |
| `build_runner` fails or generated files are missing | [Fix code generation problems](code-generation-problems.md) |
| The same operation behaves differently after changing engines | [Check surprising behaviors](surprising-behaviors.md) |

When the failure is backend-specific, open the setup page for the selected
engine after identifying the failing layer. Keep the original command,
exception, and stack trace when investigating the problem.
