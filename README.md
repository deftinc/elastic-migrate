# elastic-migrate

Easy elasticsearch index migrations.

## Install
```
npm install elastic-migrate
```

## Usage

Most commands rely on ELASTICSEARCH_HOST being set as an environment variable. You can do this in many ways, but typically locally it'll be similar to one of the following:
```
ELASTICSEARCH_HOST=localhost:9200 elastic-migrate list
-or-
export ELASTICSEARCH_HOST=localhost:9200
elastic-migrate list
```

### One-time setup

```
elastic-migrate setup
Done.
```

### List migrations locally and on elasticsearch cluster
```
elastic-migrate list
[ ] 20181013140148 create_foo_bar
[ ] 20181013140201 create_baz
[ ] 20181013140207 remove_bar
[ ] 20181013140224 remove_foo
```

### Migrate up

Migrate up can take an option in VERSION to migrate up to a specific version.
```
$ VERSION=20181013140148 elastic-migrate up
Migrating version=20181013140148 create_foo_bar
	[ElasticMigration] creating index=bar
	[ElasticMigration] adding alias index=bar alias=foo

elastic-migrate list
[*] 20181013140148 create_foo_bar
[ ] 20181013140201 create_baz
[ ] 20181013140207 remove_bar
[ ] 20181013140224 remove_foo

```

Migrate up will by default run all the migrations to the latest version.

```
elastic-migrate up
Migrating version=20181013140201 create_baz
	[ElasticMigration] creating index=baz
	[ElasticMigration] adding alias index=baz alias=foo
Migrating version=20181013140207 remove_bar
	[ElasticMigration] removing index=bar
Migrating version=20181013140224 remove_foo
	[ElasticMigration] removing alias index=baz alias=foo

elastic-migrate list
[*] 20181013140148 create_foo_bar
[*] 20181013140201 create_baz
[*] 20181013140207 remove_bar
[*] 20181013140224 remove_foo
```

### Migrate down

Migrate down will by default migrate down one version.

```
elastic-migrate list
[*] 20181013140148 create_foo_bar
[*] 20181013140201 create_baz
[*] 20181013140207 remove_bar
[*] 20181013140224 remove_foo

elastic-migrate down
Migrating version=20181013140224 remove_foo
	[ElasticMigration] adding alias index=baz alias=foo

elastic-migrate list
[*] 20181013140148 create_foo_bar
[*] 20181013140201 create_baz
[*] 20181013140207 remove_bar
[ ] 20181013140224 remove_foo
```

Migrate can also take a version to migrate down to a specifc version.

```
$ VERSION=20181013140148 elastic-migrate list
[*] 20181013140148 create_foo_bar
[*] 20181013140201 create_baz
[*] 20181013140207 remove_bar
[ ] 20181013140224 remove_foo

$ VERSION=20181013140148 elastic-migrate down
Migrating version=20181013140207 remove_bar
	[ElasticMigration] creating index=bar
	[ElasticMigration] adding alias index=bar alias=foo
Migrating version=20181013140201 create_baz
	[ElasticMigration] removing alias index=baz alias=foo
	[ElasticMigration] removing index=baz
Migrating version=20181013140148 create_foo_bar
	[ElasticMigration] removing alias index=bar alias=foo
	[ElasticMigration] removing index=bar

elastic-migrate list
[ ] 20181013140148 create_foo_bar
[ ] 20181013140201 create_baz
[ ] 20181013140207 remove_bar
[ ] 20181013140224 remove_foo
```

### Generate a migration

```
$ elastic-migrate generate <DESCRIPTION_OF_MIGRATION>
```

## License

This project is licensed under the terms of the MIT license.
