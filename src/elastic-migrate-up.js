#!/usr/bin/env node
const path = require('path');
const program = require('commander');
const {
  exitSuccessfully,
  exitWithError,
  setClient,
  getClient,
  getMigrations,
  elasticMigrateMigrationsIndexName,
  elasticMigrateMigrationsPath,
} = require('./elastic-migrate-utils');

let host, version;

const commandTimestamp = new Date().getTime();

const logMigrationRun = async migration => {
  return getClient().index({
    index: elasticMigrateMigrationsIndexName,
    type: '_doc',
    body: {
      version: migration.version,
      description: migration.description,
      migratedAt: commandTimestamp
    },
  });
};

const targetVersion = migrations => {
  return version || migrations[migrations.length - 1].version
};

program
  .arguments('[version]')
  .action((versionV) => {
    version = versionV;
  })
  .parse(process.argv);

(async () => {
  host = process.env.ELASTICSEARCH_HOST;
  if (!host) {
    exitWithError("Error: Must provide host");
  }
  try {
    await setClient(host);
    const migrations = await getMigrations();
    const migrationsToProcess = migrations.filter(migration => {
      return !migration.isMigrated && migration.version <= targetVersion(migrations);
    });
    if(migrationsToProcess.length === 0) {
      exitSuccessfully("Nothing to do.");
    }
    for(const migration of migrationsToProcess) {
      console.log(`Migrating version=${migration.version} ${migration.description}`);
      const MigrationClass = require(migration.filepath);
      const migrationInstance = new MigrationClass(getClient());
      await migrationInstance.up();
      await logMigrationRun(migration);
    };
  } catch (error) {
    console.log(error.stack);
    exitWithError(`Unknown error:\n${error}`);
  }
})();
