## 2.0.0-dev.4

 - Bump version to keep all packages in the workspace in lockstep.

## 2.0.0-dev.3

 - Bump version to keep all packages in the workspace in lockstep.

## 2.0.0-dev.2

 - **FIX**: fix licence header. ([287219ca](https://github.com/ezgrs/dorm.git/commit/287219ca9700b537a6e13211df12139440817d9d))
 - **DOCS**: replace beet-software/dorm -> ezgrs/dorm. ([b73b15d2](https://github.com/ezgrs/dorm.git/commit/b73b15d2fc7860c280311fb9a11299e70102392b))
 - **DOCS**: standardize READMEs. ([0b9bc0c5](https://github.com/ezgrs/dorm.git/commit/0b9bc0c58b0c286cd1bef66885a0ad908c51525a))
 - **DOCS**: add LICENSE file to all repos. ([379c7631](https://github.com/ezgrs/dorm.git/commit/379c7631cb66824691fde003db7f2588f8f29da4))

## 2.0.0-dev.1

 - **REFACTOR**: replace StringBuffer with code_builder. ([e4886895](https://github.com/ezgrs/dorm.git/commit/e48868950d39ba68774350148db892b05e5a5c21))
 - **FIX**: fix code generation by updating dependencies. ([a5921c77](https://github.com/ezgrs/dorm.git/commit/a5921c779dd8e29a25e3166b7a495b09071852af))
 - **FIX**: add filter concatenation for Filter.limit. ([896cb95b](https://github.com/ezgrs/dorm.git/commit/896cb95b2a78686c86eace3cd76fb4ea388825e7))
 - **FEAT**: improve filtering API. ([2b7014bf](https://github.com/ezgrs/dorm.git/commit/2b7014bfc9569f8bbd2b079f3d286ac4a3471435))
 - **FEAT**: improve DerivedField API. ([5603ec2a](https://github.com/ezgrs/dorm.git/commit/5603ec2a0d55a6954dbbd1f17617668abaf6b58e))
 - **FEAT**: replace key with field parameter on Filter/Sort. ([9a44b582](https://github.com/ezgrs/dorm.git/commit/9a44b582d79b4cb4ac8a102e2f0f7ffc8935bd5e))
 - **FEAT**: replace Model.primaryKeyGenerator with $dorm$generateId. ([69524fc0](https://github.com/ezgrs/dorm.git/commit/69524fc0f68c5536e09c9db2993c73fd1d506fe0))
 - **FEAT**: add support to auto-generated IDs. ([68423b36](https://github.com/ezgrs/dorm.git/commit/68423b36e7a2b9d9abe55113612f6b466d3581ca))
 - **FEAT**: remove json_serializable from declarable dependency by user. ([d3132b6e](https://github.com/ezgrs/dorm.git/commit/d3132b6e48bd8d980f557f5211228f120bdde14b))
 - **FEAT**: add suport to transactions. ([8d4a6279](https://github.com/ezgrs/dorm.git/commit/8d4a62797589809ae888ac0897e3db8af6653321))
 - **FEAT**: improve pagination API. ([d205693d](https://github.com/ezgrs/dorm.git/commit/d205693d2c62968338146c5fc5d6d741ca9349de))
 - **FEAT**: make EntitySchema.primaryKeys canonical. ([09f88107](https://github.com/ezgrs/dorm.git/commit/09f8810775e257a05ef46544b8ec69a05ee808aa))
 - **FEAT**: add support to composite keys on Entity.fromData. ([d7fb7c4f](https://github.com/ezgrs/dorm.git/commit/d7fb7c4fa9a88259fd260878f1aa42c254f7655e))
 - **FEAT**: refactor QueryField into DerivedField. ([9aa2ceef](https://github.com/ezgrs/dorm.git/commit/9aa2ceef2dbb3a28de84da80cc2427162c0ba034))
 - **FEAT**: improve primary key generation. ([797b672a](https://github.com/ezgrs/dorm.git/commit/797b672a59f2a9d0052562a14fc37dcfb4e74d59))
 - **FEAT**: improve relationships querying by the client. ([f2bc7545](https://github.com/ezgrs/dorm.git/commit/f2bc75451274177a3832f4b7dd84df03afc5a4a1))
 - **FEAT**: add initial support to engine-agnostic relationships. ([05f43745](https://github.com/ezgrs/dorm.git/commit/05f4374503567ee06f34bc171e14980d221670fa))
 - **FEAT**: remove Entity.tableName in favor of Entity.schema.tableName. ([42f69a48](https://github.com/ezgrs/dorm.git/commit/42f69a480de9ac9dce27ee8bf3963f024519e7ae))
 - **FEAT**: add EntitySchema to Entity. ([38640aaf](https://github.com/ezgrs/dorm.git/commit/38640aaf0750659c46aed1d5c186f3e8ab25538c))
 - **FEAT**: add support to copy_with_extension_gen. ([da202eb0](https://github.com/ezgrs/dorm.git/commit/da202eb0ada17f82bd624834d888e4b47a200308))
 - **FEAT**: adapt code to accept I as type parameter. ([2ccc56f8](https://github.com/ezgrs/dorm.git/commit/2ccc56f80e724368f978c2d5a6b0a080d21ab1d3))
 - **FEAT**: update examples. ([4576e6e8](https://github.com/ezgrs/dorm.git/commit/4576e6e830fd28c773480ceb5608b802a9993583))
 - **FEAT**: add sorted method to Filter. ([10836361](https://github.com/ezgrs/dorm.git/commit/10836361d4fd2339af45ff543228635eb45ead81))
 - **FEAT**: change Filter to BaseFilter. ([dba05767](https://github.com/ezgrs/dorm.git/commit/dba0576753596e7f1a16ee0bee8c654b2f7d490f))

