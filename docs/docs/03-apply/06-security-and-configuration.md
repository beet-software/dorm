# Configure backend security boundaries

dORM maps generated models to backend operations. It does not provide one access-control policy that applies to BLoC, Firebase, and MySQL.

Security configuration is therefore split between the application, the selected engine, and the backend:

| Layer | Observable responsibility |
| --- | --- |
| Generated model/entity | Field names, identity mapping, and serialization values |
| dORM framework | Repository operations and engine-neutral filters/relationships |
| Firebase | Authentication state and Realtime Database rules |
| MySQL | Connection credentials, database permissions, and server configuration |
| BLoC | In-process state with no external authorization mechanism |

## Configure Firebase authorization

The Firebase engine exposes Firebase Authentication through `FirebaseInstance`, but dORM does not define authorization rules for the application. Realtime Database rules decide whether a Firebase operation is allowed.

A rules file can require an authenticated Firebase user:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

With rules of this form, the application must establish a Firebase Authentication user before repository reads and writes are allowed. The dORM repository does not log the user in or change the rules.

Start the local Database Emulator with the rules file configured by Firebase CLI:

```shell
firebase emulators:start --only database
```

The emulator uses the local rules configuration. Hosted Firebase uses the rules deployed to the selected project.

## Configure MySQL credentials

The MySQL engine receives an already-created `MySQLConnection`. The application supplies the host, port, username, and password:

```dart
final MySQLConnection connection =
    await MySQLConnection.createConnection(
  host: env['MYSQL_HOST']!,
  port: int.parse(env['MYSQL_PORT']!),
  userName: env['MYSQL_USERNAME']!,
  password: env['MYSQL_PASSWORD']!,
);
```

The package does not provide an application-level roles or permissions abstraction. MySQL account permissions and server access rules remain outside the dORM framework.

## Understand query parameterization

The MySQL query implementation sends filter values as parameters for value, text, and range predicates. For example, a value filter becomes a SQL predicate with a bound `:value` parameter.

Table and column identifiers are assembled from generated schema metadata. They are not values passed through the same parameter map. The identifier source is the model and field declaration, so model names and persisted field names become part of the generated schema contract.

Firebase uses Firebase Database query methods such as `equalTo`, `startAt`, `endAt`, and `orderByChild` instead of constructing SQL.

## Keep secrets outside model and configuration source

Connection passwords and Firebase configuration values are application deployment inputs. Use environment or platform configuration for those values:

```dotenv
MYSQL_PASSWORD=[PLACEHOLDER: provide at deployment time]
```

The dORM packages do not provide a secrets store, automatic redaction, or a logging policy. The dORM and engine APIs do not establish a guarantee that arbitrary application logs will omit model values or credentials.

## Understand the BLoC boundary

The BLoC engine stores records in process memory. It has no backend authorization layer because it does not connect to an external database. Any access control around the in-memory repository must be applied by the application code that holds the `Dorm` instance.

The framework also does not expose a general access-control contract shared by all engines. Treat backend rules and application ownership of the engine as separate from generated model mapping.
