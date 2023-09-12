import 'dart:io';

import 'package:args/args.dart';
import 'package:dorm_mysql_database/dorm_mysql_database.dart';
import 'package:mysql_client/mysql_client.dart';

import 'models.dart';

List<String> shellSplit(String string) {
  final List<String> tokens = [];
  bool escaping = false;
  String quoteChar = ' ';
  bool quoting = false;
  int lastCloseQuoteIndex = -1;
  StringBuffer current = StringBuffer();

  for (int i = 0; i < string.length; i++) {
    String c = string[i];
    if (escaping) {
      current.write(c);
      escaping = false;
    } else if (c == '\\' && !(quoting && quoteChar == '\'')) {
      escaping = true;
    } else if (quoting && c == quoteChar) {
      quoting = false;
      lastCloseQuoteIndex = i;
    } else if (!quoting && (c == '\'' || c == '"')) {
      quoting = true;
      quoteChar = c;
    } else if (!quoting && c.trim().isEmpty) {
      if (current.length > 0 || lastCloseQuoteIndex == (i - 1)) {
        tokens.add(current.toString());
        current = StringBuffer();
      }
    } else {
      current.write(c);
    }
  }
  if (current.length > 0 || lastCloseQuoteIndex == (string.length - 1)) {
    tokens.add(current.toString());
  }
  return tokens;
}

Future<void> run(Dorm dorm) async {
  final ArgParser parser = ArgParser();
  parser.addCommand('peek');
  parser.addCommand('peekAll');
  parser.addCommand('peekAllKeys');
  parser.addCommand('pop');
  parser.addCommand('put')
    ..addOption('name', mandatory: true)
    ..addOption('age', mandatory: true)
    ..addFlag('active', defaultsTo: false);
  parser.addCommand('push')
    ..addOption('id', mandatory: true)
    ..addOption('name', mandatory: true)
    ..addOption('age', mandatory: true)
    ..addFlag('active', defaultsTo: false);
  parser.addCommand('popKeys').addMultiOption('id');

  for (;;) {
    stdout.write('> ');
    final String? line = stdin.readLineSync()?.trim();
    if (line == null) break;
    if (line == 'exit') return;

    final List<String> args = shellSplit(line);
    final ArgResults results = parser.parse(args);
    final ArgResults? command = results.command;
    if (command == null) {
      stderr.writeln('invalid command: ${args[0]}');
      continue;
    }

    final String? commandName = command.name;
    if (commandName == null) continue;
    switch (commandName) {
      case 'put':
        {
          final UserData data = UserData(
            name: command['name'],
            active: command['active'],
            age: int.parse(command['age']),
          );
          final User user = await dorm.users.repository.put(
            const UserDependency(),
            data,
          );
          print({'id': user.id, ...user.toJson()});
        }
      case 'peek':
        {
          final String? id = command.rest.singleOrNull;
          if (id == null) {
            stderr.writeln('must pass an ID to read');
            continue;
          }
          final User? user = await dorm.users.repository.peek(id);
          print(user?.toJson());
        }
      case 'push':
        {
          final User user = User(
            id: command['id'],
            name: command['name'],
            active: command['active'],
            age: int.parse(command['age']),
          );
          await dorm.users.repository.push(user);
          print({'id': user.id, ...user.toJson()});
        }
      case 'peekAll':
        {
          final List<User> users = await dorm.users.repository.peekAll();
          if (users.isEmpty) {
            print('');
          } else {
            for (User user in users) {
              print({'id': user.id, ...user.toJson()});
            }
          }
        }
      case 'peekAllKeys':
        {
          final List<String> keys = await dorm.users.repository.peekAllKeys();
          if (keys.isEmpty) {
            print('');
          } else {
            for (String key in keys) {
              print(key);
            }
          }
        }
      case 'pop':
        {
          final String? id = command.rest.singleOrNull;
          if (id == null) {
            stderr.writeln('must pass an ID to delete');
            continue;
          }
          await dorm.users.repository.pop(id);
          print('');
        }
      case 'popKeys':
        {
          final List<String> ids = command['id'];
          if (ids.isEmpty) {
            stderr.writeln('must pass at least one ID to delete');
            continue;
          }
          await dorm.users.repository.popKeys(ids);
          print('');
        }
    }
  }
}

void main() async {
  final MySQLConnection connection = await MySQLConnection.createConnection(
    host: 'localhost',
    port: 3306,
    userName: 'root',
    password: 'root',
    databaseName: 'dbroot',
  );
  await connection.connect();
  try {
    final Engine engine = Engine(connection);
    final Dorm dorm = Dorm(engine);
    await run(dorm);
  } finally {
    await connection.close();
  }
}
