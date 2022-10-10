import 'package:dorm/dorm.dart';
import 'package:dorm_memory_database/src/memory_instance.dart';
import 'package:dorm_memory_database/src/param_type.dart';
import 'package:test/test.dart';

void main() {
  test('ordering by a specified child key', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    expect(
      instance.get([ParamType.orderByChild('height')]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('length')]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('weight')]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      }),
    );
  });
  test('ordering by a specified child key, filtered by head', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    expect(
      instance
          .get([ParamType.orderByChild('height'), ParamType.limitToFirst(1)]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      }),
    );
    expect(
      instance
          .get([ParamType.orderByChild('length'), ParamType.limitToFirst(1)]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
    expect(
      instance
          .get([ParamType.orderByChild('weight'), ParamType.limitToFirst(1)]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
  });
  test('ordering by a specified child key, filtered by tail', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    expect(
      instance
          .get([ParamType.orderByChild('height'), ParamType.limitToLast(1)]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
    expect(
      instance
          .get([ParamType.orderByChild('length'), ParamType.limitToLast(1)]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      }),
    );
    expect(
      instance
          .get([ParamType.orderByChild('weight'), ParamType.limitToLast(1)]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      }),
    );
  });
  test('ordering by a specified child key, filtered by floor', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    expect(
      instance.get([ParamType.orderByChild('height'), ParamType.startAt(5)]),
      equals({}),
    );
    expect(
      instance.get([ParamType.orderByChild('height'), ParamType.startAt(3)]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('height'), ParamType.startAt(1)]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
  });
  test('ordering by a specified child key, filtered by ceiling', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    expect(
      instance.get([ParamType.orderByChild('weight'), ParamType.endAt(1000)]),
      equals({}),
    );
    expect(
      instance.get([ParamType.orderByChild('weight'), ParamType.endAt(3000)]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('weight'), ParamType.endAt(5000)]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
  });
  test('ordering by a specified child key, filtered by value', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    expect(
      instance.get([ParamType.orderByChild('weight'), ParamType.equalTo(1)]),
      equals({}),
    );
    expect(
      instance.get([ParamType.orderByChild('weight'), ParamType.equalTo(2500)]),
      equals({
        'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('weight'), ParamType.equalTo(5000)]),
      equals({
        'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      }),
    );
  });
  test('ordering by a specified nested key', () {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {
        'dimensions': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      },
      'stegosaurus': {
        'dimensions': {'height': 4, 'length': 9, 'weight': 2500},
      },
    });
    expect(
      instance.get([ParamType.orderByChild('dimensions/height')]),
      equals({
        'lambeosaurus': {
          'dimensions': {'height': 2.1, 'length': 12.5, 'weight': 5000}
        },
        'stegosaurus': {
          'dimensions': {'height': 4, 'length': 9, 'weight': 2500}
        },
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('dimensions/length')]),
      equals({
        'stegosaurus': {
          'dimensions': {'height': 4, 'length': 9, 'weight': 2500},
        },
        'lambeosaurus': {
          'dimensions': {'height': 2.1, 'length': 12.5, 'weight': 5000}
        },
      }),
    );
    expect(
      instance.get([ParamType.orderByChild('dimensions/weight')]),
      equals({
        'stegosaurus': {
          'dimensions': {'height': 4, 'length': 9, 'weight': 2500}
        },
        'lambeosaurus': {
          'dimensions': {'height': 2.1, 'length': 12.5, 'weight': 5000}
        },
      }),
    );
  });
  test('reading data using object', () {
    final MemoryInstance instance = MemoryInstance({});
    instance.ref.child('users').set({
      'alanisawesome': {
        'date_of_birth': 'June 23, 1912',
        'full_name': 'Alan Turing'
      },
      'gracehop': {
        'date_of_birth': 'December 9, 1906',
        'full_name': 'Grace Hopper'
      },
    });
    expect(instance.get(), {
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing'
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper'
        },
      }
    });
  });
  test('reading data using child', () {
    final MemoryInstance instance = MemoryInstance({});
    final Reference ref = instance.ref.child('users');
    ref
        .child('alanisawesome')
        .set({'date_of_birth': 'June 23, 1912', 'full_name': 'Alan Turing'});
    ref.child('gracehop').set(
        {'date_of_birth': 'December 9, 1906', 'full_name': 'Grace Hopper'});
    expect(instance.get(), {
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing'
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper'
        },
      }
    });
  });
  test('reading data using children', () async {
    final MemoryInstance instance = MemoryInstance({});
    final Reference ref = instance.ref.child('users');
    ref
        .child('alanisawesome')
        .set({'date_of_birth': 'June 23, 1912', 'full_name': 'Alan Turing'});
    ref.child('gracehop').set(
        {'date_of_birth': 'December 9, 1906', 'full_name': 'Grace Hopper'});
    expect(
      await ref.get(),
      equals({
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
        },
      }),
    );
    expect(
      await ref.getChildren(),
      equals({
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
        },
      }),
    );
  });
  test('updating data individually', () {
    final MemoryInstance instance = MemoryInstance({
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
        },
      }
    });
    final Reference ref = instance.ref.child('users');
    ref.child('alanisawesome').update({'nickname': 'Alan The Machine'});
    ref.child('gracehop').update({'nickname': 'Amazing Grace'});
    expect(instance.get(), {
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
          'nickname': 'Alan The Machine',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
          'nickname': 'Amazing Grace',
        },
      }
    });
  });
  test('updating data consecutively using keys', () {
    final MemoryInstance instance = MemoryInstance({
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
        },
      }
    });
    final Reference ref = instance.ref.child('users');
    ref.update({
      'alanisawesome/nickname': 'Alan The Machine',
      'gracehop/nickname': 'Amazing Grace',
    });
    expect(instance.get(), {
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
          'nickname': 'Alan The Machine',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
          'nickname': 'Amazing Grace',
        },
      }
    });
  });
  test('updating data consecutively using objects', () {
    final MemoryInstance instance = MemoryInstance({
      'users': {
        'alanisawesome': {
          'date_of_birth': 'June 23, 1912',
          'full_name': 'Alan Turing',
        },
        'gracehop': {
          'date_of_birth': 'December 9, 1906',
          'full_name': 'Grace Hopper',
        },
      }
    });
    final Reference ref = instance.ref.child('users');
    ref.update({
      'alanisawesome': {
        'nickname': 'Alan The Machine',
      },
      'gracehop': {
        'nickname': 'Amazing Grace',
      },
    });
    expect(instance.get(), {
      'users': {
        'alanisawesome': {
          'nickname': 'Alan The Machine',
        },
        'gracehop': {
          'nickname': 'Amazing Grace',
        },
      }
    });
  });
  test('listening to data', () async {
    final MemoryInstance instance = MemoryInstance({
      'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000},
      'stegosaurus': {'height': 4, 'length': 9, 'weight': 2500},
    });
    final Stream<Object?> stream = instance
        .listen([ParamType.orderByChild('weight'), ParamType.equalTo(5000)]);
    expect(
        await stream.first,
        equals({
          'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000}
        }));
    instance.set('lambeosaurus/weight', 4000);
    expect(await stream.first, equals({}));
    instance.set('lambeosaurus/weight', 5000);
    expect(
        await stream.first,
        equals({
          'lambeosaurus': {'height': 2.1, 'length': 12.5, 'weight': 5000}
        }));
  });
}
