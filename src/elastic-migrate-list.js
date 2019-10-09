#!/usr/bin/env node
const program = require('commander');
const {
  setClient,
  getMigrations,
  exitSuccessfully,
  exitWithError,
} = require('./elastic-migrate-utils');

let host;

const printMigrations = (migrations) => {
  migrations.forEach((migration) => {
    console.log(`[${migration.isMigrated ? '*' : ' '}] ${migration.version} ${migration.description}`);
  });
}

program
  .action(() => {})
  .parse(process.argv);

(async () => {

  host = process.env.ELASTICSEARCH_HOST;
  if (!host) {
    exitWithError("Error: Must provide host");
  }
  try {
    await setClient(host);
    const migrations = await getMigrations();
    if(migrations.length === 0) {
      exitSuccessfully("No local migrations files");
    }
    printMigrations(migrations);
  } catch (error) {
    exitWithError(`Unknown error\n${error}`);
  }
})();
