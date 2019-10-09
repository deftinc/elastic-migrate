#!/usr/bin/env node
const program = require('commander');
const path = require('path');
const util = require('util');
const mkdir = util.promisify(require('fs').mkdir);

const {
  checkIfMigrationIndexExists,
  createMigrationsIndex,
  exitWithError,
  exitSuccessfully,
  getClient,
  setClient,
  elasticMigrateMigrationsIndexName,
} = require('./elastic-migrate-utils');

let host;

program
  .action(() => {})
  .parse(process.argv);

(async () => {
  host = process.env.ELASTICSEARCH_HOST;
  if (!host) {
    exitWithError("Error: Must provide host");
  }
  try {
    await mkdir(path.resolve('./migrations'), { recursive: true });
  } catch (error) {
    if(error.code !== 'EEXIST') {
      exitWithError("Error creating the migrations directory")
    }
  }
  try {
    await setClient(host);
    const indexExists = await checkIfMigrationIndexExists();
    if (indexExists) {
      exitSuccessfully("Already ran setup. Exiting.")
    } else {
      const resp = await createMigrationsIndex();
      if (resp.acknowledged) {
        exitSuccessfully("Done.");
      }
    }
  } catch (error) {
    exitWithError(`Unknown error\n${error}`);
  }
})();
