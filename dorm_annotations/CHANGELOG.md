## 2.0.0-dev.5

 - Bump "dorm_annotations" to `2.0.0-dev.5`.

## 2.0.0-dev.4

 - **FIX**: change example pubspec's name to avoid conflict. ([a14e9ace](https://github.com/ezgrs/dorm.git/commit/a14e9acec359f78ce6108efb46a5bc5a0c3c3e97))
 - **DOCS**: add example on pub.dev standards. ([5dd402d7](https://github.com/ezgrs/dorm.git/commit/5dd402d7d020f90c4a50a504936a60817f92330e))

## 2.0.0-dev.3

 - Bump "dorm_annotations" to `2.0.0-dev.3`.

## 2.0.0-dev.2

 - **DOCS**: replace beet-software/dorm -> ezgrs/dorm. ([b73b15d2](https://github.com/ezgrs/dorm.git/commit/b73b15d2fc7860c280311fb9a11299e70102392b))
 - **DOCS**: standardize READMEs. ([0b9bc0c5](https://github.com/ezgrs/dorm.git/commit/0b9bc0c58b0c286cd1bef66885a0ad908c51525a))
 - **DOCS**: add LICENSE file to all repos. ([379c7631](https://github.com/ezgrs/dorm.git/commit/379c7631cb66824691fde003db7f2588f8f29da4))

## 2.0.0-dev.1

 - **REFACTOR**: improve generation by providing a spec object. ([2bfa232c](https://github.com/ezgrs/dorm.git/commit/2bfa232ccb558468d05c694468f632682eae2331))
 - **REFACTOR**: replace StringBuffer with code_builder. ([e4886895](https://github.com/ezgrs/dorm.git/commit/e48868950d39ba68774350148db892b05e5a5c21))
 - **FIX**: changes drawing.dart to match .dorm.dart. ([4606613d](https://github.com/ezgrs/dorm.git/commit/4606613d7eee95f6d1cd190992a336005a0e0aef))
 - **FIX**: fix code generation by updating dependencies. ([a5921c77](https://github.com/ezgrs/dorm.git/commit/a5921c779dd8e29a25e3166b7a495b09071852af))
 - **FEAT**: add support to composite keys on Entity.fromData. ([d7fb7c4f](https://github.com/ezgrs/dorm.git/commit/d7fb7c4fa9a88259fd260878f1aa42c254f7655e))
 - **FEAT**: replace key with field parameter on Filter/Sort. ([9a44b582](https://github.com/ezgrs/dorm.git/commit/9a44b582d79b4cb4ac8a102e2f0f7ffc8935bd5e))
 - **FEAT**: improve pagination API. ([d205693d](https://github.com/ezgrs/dorm.git/commit/d205693d2c62968338146c5fc5d6d741ca9349de))
 - **FEAT**: add date and datetime to DerivedTransform. ([d6311063](https://github.com/ezgrs/dorm.git/commit/d6311063aea248b921efecbb41583b423fdc75ac))
 - **FEAT**: make EntitySchema.primaryKeys canonical. ([09f88107](https://github.com/ezgrs/dorm.git/commit/09f8810775e257a05ef46544b8ec69a05ee808aa))
 - **FEAT**: replace Model.primaryKeyGenerator with $dorm$generateId. ([69524fc0](https://github.com/ezgrs/dorm.git/commit/69524fc0f68c5536e09c9db2993c73fd1d506fe0))
 - **FEAT**: makes *Field.name parameter optional. ([cc42bf84](https://github.com/ezgrs/dorm.git/commit/cc42bf842c356d88c0b9125fd3a1b3ba80e32397))
 - **FEAT**: improve DerivedField API. ([5603ec2a](https://github.com/ezgrs/dorm.git/commit/5603ec2a0d55a6954dbbd1f17617668abaf6b58e))
 - **FEAT**: refactor QueryField into DerivedField. ([9aa2ceef](https://github.com/ezgrs/dorm.git/commit/9aa2ceef2dbb3a28de84da80cc2427162c0ba034))
 - **FEAT**: improve primary key generation. ([797b672a](https://github.com/ezgrs/dorm.git/commit/797b672a59f2a9d0052562a14fc37dcfb4e74d59))
 - **FEAT**: improve relationships querying by the client. ([f2bc7545](https://github.com/ezgrs/dorm.git/commit/f2bc75451274177a3832f4b7dd84df03afc5a4a1))
 - **FEAT**: add initial support to engine-agnostic relationships. ([05f43745](https://github.com/ezgrs/dorm.git/commit/05f4374503567ee06f34bc171e14980d221670fa))
 - **FEAT**: remove Entity.tableName in favor of Entity.schema.tableName. ([42f69a48](https://github.com/ezgrs/dorm.git/commit/42f69a480de9ac9dce27ee8bf3963f024519e7ae))
 - **FEAT**: add EntitySchema to Entity. ([38640aaf](https://github.com/ezgrs/dorm.git/commit/38640aaf0750659c46aed1d5c186f3e8ab25538c))
 - **FEAT**: add support to copy_with_extension_gen. ([da202eb0](https://github.com/ezgrs/dorm.git/commit/da202eb0ada17f82bd624834d888e4b47a200308))
 - **FEAT**: add support to auto-generated IDs. ([68423b36](https://github.com/ezgrs/dorm.git/commit/68423b36e7a2b9d9abe55113612f6b466d3581ca))
 - **FEAT**: make `name` parameter optional on Model annotation. ([d894fae3](https://github.com/ezgrs/dorm.git/commit/d894fae32b8d694f08eded48cbcc54c9e412a5dc))
 - **FEAT**: change Filter to BaseFilter. ([dba05767](https://github.com/ezgrs/dorm.git/commit/dba0576753596e7f1a16ee0bee8c654b2f7d490f))
 - **FEAT**: make CustomUidValue accept String as parameter. ([51468fc4](https://github.com/ezgrs/dorm.git/commit/51468fc48f8e1552bbfb46dea98ca04be92dbab8))
 - **FEAT**: add Model.idType. ([ce55ec37](https://github.com/ezgrs/dorm.git/commit/ce55ec379dd285d29f4db92005dcfb186b4d2cc9))
 - **FEAT**: finishes template feature. ([d88f668b](https://github.com/ezgrs/dorm.git/commit/d88f668bd07fb3cc12d4d4307cec019f1438c30f))
 - **FEAT**: add initial code. ([d9fd709e](https://github.com/ezgrs/dorm.git/commit/d9fd709ec71dd6c6ba1e9d4911631a8b4c40a198))
 - **FEAT**: removes unused_element warning for schema data class. ([0f884b04](https://github.com/ezgrs/dorm.git/commit/0f884b04231e5f5375c3aa49f93631e0ba960094))
 - **FEAT**: removes unused_element warning for dummy model classes. ([fb20721a](https://github.com/ezgrs/dorm.git/commit/fb20721a28826bb4e0ab535b65d092e71a87cb11))
 - **FEAT**: update generated examples. ([706fe056](https://github.com/ezgrs/dorm.git/commit/706fe056ccc8a79056ff698b5bad5ec5afeaa748))
 - **FEAT**: remove json_serializable from declarable dependency by user. ([d3132b6e](https://github.com/ezgrs/dorm.git/commit/d3132b6e48bd8d980f557f5211228f120bdde14b))
 - **FEAT**: make `name` parameter optional on Model annotation. ([7022154a](https://github.com/ezgrs/dorm.git/commit/7022154a409292d10199b63cc13b9e6c4b1fbb10))
 - **FEAT**: replace UidType and CustomUidValue by `primaryKeyGenerator` function. ([f8c5676d](https://github.com/ezgrs/dorm.git/commit/f8c5676dc5e05457a4b5eb261a8f7ddf9f05f90a))
 - **FEAT**: add `ModelFieldOutput` class. ([98cb5b2c](https://github.com/ezgrs/dorm.git/commit/98cb5b2c29392f017cfd16f73755445c7f5637d3))
 - **FEAT**: add suport to transactions. ([8d4a6279](https://github.com/ezgrs/dorm.git/commit/8d4a62797589809ae888ac0897e3db8af6653321))

