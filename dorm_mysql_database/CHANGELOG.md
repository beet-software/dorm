## 2.0.0-dev.3

 - Bump version to keep all packages in the workspace in lockstep.

## 2.0.0-dev.2

 - **FEAT**: remove schema generator. ([6f7d52a4](https://github.com/ezgrs/dorm.git/commit/6f7d52a44851ec92c09d40f9e9acd892274cf8a7))
 - **FEAT**: add license header. ([abe8bae6](https://github.com/ezgrs/dorm.git/commit/abe8bae62ab5854ee8b648dfd5cf6e958cdd0caf))
 - **DOCS**: replace beet-software/dorm -> ezgrs/dorm. ([b73b15d2](https://github.com/ezgrs/dorm.git/commit/b73b15d2fc7860c280311fb9a11299e70102392b))
 - **DOCS**: standardize READMEs. ([0b9bc0c5](https://github.com/ezgrs/dorm.git/commit/0b9bc0c58b0c286cd1bef66885a0ad908c51525a))
 - **DOCS**: add README. ([d4c78343](https://github.com/ezgrs/dorm.git/commit/d4c78343ac5f225cf988d01b7d0370f266520bd5))

## 2.0.0-dev.1

 - **REFACTOR**: remove conditional of custom types. ([0600d4de](https://github.com/ezgrs/dorm.git/commit/0600d4de72e0f6415dbbd159688f57bcf34547bf))
 - **REFACTOR**: remove handling multiple executions of range. ([b0590ad3](https://github.com/ezgrs/dorm.git/commit/b0590ad3cf1ccfd94c32b47fbf2799421776c03c))
 - **REFACTOR**: removes redundant conversion to string when applying filters. ([4b6e0885](https://github.com/ezgrs/dorm.git/commit/4b6e0885177b48ecaf96638face24051e9518c43))
 - **REFACTOR**: uses named parameters when injecting filter arguments. ([ba3d82ee](https://github.com/ezgrs/dorm.git/commit/ba3d82ee4f553297141c66b26b43b7f1d5a6676c))
 - **REFACTOR**: improve DateTime to SQL formatting. ([cd1e4d2b](https://github.com/ezgrs/dorm.git/commit/cd1e4d2bb824a460d4a2d6e702aebe7478eaccc4))
 - **REFACTOR**: add Relationship to its own file. ([3e665d54](https://github.com/ezgrs/dorm.git/commit/3e665d547f405743562af365c50062d0808d4c67))
 - **FIX**: fix code generation by updating dependencies. ([a5921c77](https://github.com/ezgrs/dorm.git/commit/a5921c779dd8e29a25e3166b7a495b09071852af))
 - **FIX**: add implementation for milliseconds on `Filter.date`. ([4c3e12a7](https://github.com/ezgrs/dorm.git/commit/4c3e12a7ca333b36409c58a5df7fd5754abb5e7a))
 - **FIX**: use SQL's IN operator for `popKeys` method. ([01fbb96b](https://github.com/ezgrs/dorm.git/commit/01fbb96b2d107ab75f6fdee1291543fdc71c5ec9))
 - **FEAT**: improve filtering API. ([2b7014bf](https://github.com/ezgrs/dorm.git/commit/2b7014bfc9569f8bbd2b079f3d286ac4a3471435))
 - **FEAT**: improve DerivedField API. ([5603ec2a](https://github.com/ezgrs/dorm.git/commit/5603ec2a0d55a6954dbbd1f17617668abaf6b58e))
 - **FEAT**: replace key with field parameter on Filter/Sort. ([9a44b582](https://github.com/ezgrs/dorm.git/commit/9a44b582d79b4cb4ac8a102e2f0f7ffc8935bd5e))
 - **FEAT**: add support to auto-generated IDs. ([68423b36](https://github.com/ezgrs/dorm.git/commit/68423b36e7a2b9d9abe55113612f6b466d3581ca))
 - **FEAT**: remove json_serializable from declarable dependency by user. ([d3132b6e](https://github.com/ezgrs/dorm.git/commit/d3132b6e48bd8d980f557f5211228f120bdde14b))
 - **FEAT**: add suport to transactions. ([8d4a6279](https://github.com/ezgrs/dorm.git/commit/8d4a62797589809ae888ac0897e3db8af6653321))
 - **FEAT**: improve pagination API. ([d205693d](https://github.com/ezgrs/dorm.git/commit/d205693d2c62968338146c5fc5d6d741ca9349de))
 - **FEAT**: make EntitySchema.primaryKeys canonical. ([09f88107](https://github.com/ezgrs/dorm.git/commit/09f8810775e257a05ef46544b8ec69a05ee808aa))
 - **FEAT**: add support to composite keys on Entity.fromData. ([d7fb7c4f](https://github.com/ezgrs/dorm.git/commit/d7fb7c4fa9a88259fd260878f1aa42c254f7655e))
 - **FEAT**: refactor QueryField into DerivedField. ([9aa2ceef](https://github.com/ezgrs/dorm.git/commit/9aa2ceef2dbb3a28de84da80cc2427162c0ba034))
 - **FEAT**: improve primary key generation. ([797b672a](https://github.com/ezgrs/dorm.git/commit/797b672a59f2a9d0052562a14fc37dcfb4e74d59))
 - **FEAT**: add initial support to engine-agnostic relationships. ([05f43745](https://github.com/ezgrs/dorm.git/commit/05f4374503567ee06f34bc171e14980d221670fa))
 - **FEAT**: remove Entity.tableName in favor of Entity.schema.tableName. ([42f69a48](https://github.com/ezgrs/dorm.git/commit/42f69a480de9ac9dce27ee8bf3963f024519e7ae))
 - **FEAT**: add EntitySchema to Entity. ([38640aaf](https://github.com/ezgrs/dorm.git/commit/38640aaf0750659c46aed1d5c186f3e8ab25538c))
 - **FEAT**: add support to copy_with_extension_gen. ([da202eb0](https://github.com/ezgrs/dorm.git/commit/da202eb0ada17f82bd624834d888e4b47a200308))
 - **FEAT**: change Filter to BaseFilter. ([dba05767](https://github.com/ezgrs/dorm.git/commit/dba0576753596e7f1a16ee0bee8c654b2f7d490f))
 - **FEAT**: implements range filter. ([6b3e49b3](https://github.com/ezgrs/dorm.git/commit/6b3e49b3f12be0ffb94afc93436b351dabc10de9))
 - **FEAT**: implements `Filter.date`. ([98f499e3](https://github.com/ezgrs/dorm.git/commit/98f499e382bab92c015d0393ff6a3726a76e038a))
 - **FEAT**: implements `popAll`. ([85066c1d](https://github.com/ezgrs/dorm.git/commit/85066c1d1d5ed3bd6b4e062f6bd1de473d4a8481))
 - **FEAT**: add support to filtering on `peekAll`. ([f92cef08](https://github.com/ezgrs/dorm.git/commit/f92cef08084218cd1075760cb96cc585ad2ba2b6))
 - **FEAT**: implements ad-hoc `pullAll` using `peekAll`. ([6da18e9b](https://github.com/ezgrs/dorm.git/commit/6da18e9b5502241740d1a33e19f67f2520d78746))
 - **FEAT**: implements `putAll` using a transaction. ([c038c917](https://github.com/ezgrs/dorm.git/commit/c038c9175f04cd9c39091901d42250f7319de807))
 - **FEAT**: implements ad-hoc `pull` using `peek`. ([783dfee7](https://github.com/ezgrs/dorm.git/commit/783dfee7cfb32971762b88ff20c807844f26eb9f))
 - **FEAT**: implements `pushAll` using a transaction. ([0f6c8d3c](https://github.com/ezgrs/dorm.git/commit/0f6c8d3ca6b1867ea6b638fc90504e28689987e3))

