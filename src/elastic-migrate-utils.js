const util = require('util');
const path = require('path');
const exec = util.promisify(require('child_process').exec);
const readdir = util.promisify(require('fs').readdir);
const elasticMigrateMigrationsIndexName = process.env.ELASTIC_MIGRATE_MIGRATIONS_INDEX_NAME || 'elastic_migrate_migrations';
const elasticMigrateMigrationsPath = process.env.ELASTIC_MIGRATE_MIGRATIONS_PATH || path.resolve('./migrations');
const {Client} = require('elasticsearch');
const ConfigurationError = require("./configuration-error");
const RuntimeError = require("./runtime-error");
const AWS = require('aws-sdk');
module.exports = class RuntimeError extends Error {};
let client;

const getClientOptions = host => {
  const options = {
    apiVersion: '6.3',
    host: process.env.ELASTICSEARCH_HOST,
    log: [{type: 'stdio', levels: []}]
  };

  if (
    process.env.ELASTICSEARCH_ACCESS_KEY &&
    process.env.ELASTICSEARCH_SECRET_KEY &&
    process.env.ELASTICSEARCH_REGION
  ) {
    options.connectionClass = require('http-aws-es');
    options.awsConfig = new AWS.Config({
      region: process.env.ELASTICSEARCH_REGION,
      credentials: new AWS.Credentials({
        accessKeyId: process.env.ELASTICSEARCH_ACCESS_KEY,
        secretAccessKey: process.env.ELASTICSEARCH_SECRET_KEY,
      }),
    });
  }

  return options;
}

function exitSuccessfully(message = "") {
  if(client) {
    client.close()
  }
  console.log(message);
  process.exit(0);
}

function exitWithError(message = "Unknown error") {
  if(client) {
    client.close()
  }
  console.error(message);
  process.exit(1);
}

async function checkConnection() {
  try {
    const isConnected = await client.ping();
    if(!isConnected) {
      exitWithError("Error connecting to host 1");
    }
  } catch (error) {
    exitWithError("Error connecting to host");
  }
  return client;
}

const setClient = async host => {
  if(!host && !process.env.ELASTICSEARCH_HOST) {
    throw new ConfigurationError("Missing environment variable ELASTICSEARCH_HOST")
  }
  client = new Client(getClientOptions(host));
  return checkConnection();
};

const getClient = () => {
  if(!client) {
    throw new RuntimeError("No client defined, use setClient()");
  }
  return client;
};

const getHostMigrations = async () => {
  const {hits: {hits}} = await getClient().search({
    index: elasticMigrateMigrationsIndexName,
    // type: "migration",
    body: {},
    size: 200,
  });
  return hits.map(hit => hit._source.version.toString());
};

const getLocalMigrations = async () => {
  const files = (await readdir(path.resolve('./migrations')))
  return files.map(item => {
      const [filename, version, description] = /(\d*)\_(.*).js/gi.exec(item);
      return {description, version, filepath: path.resolve('./migrations', filename)};
    })
    .sort((a, b) => a.version.localeCompare(b.version));
};

const getMigrations = async ({reverse} = {}) => {
  const hostMigrations = await getHostMigrations();
  const localMigrations = await getLocalMigrations();
  if(reverse) {
    localMigrations.reverse();
  }
  return localMigrations.map(migration => ({
    ...migration,
    isMigrated: hostMigrations.includes(migration.version),
  }));
};

const checkIfMigrationIndexExists = async () => {
  return getClient().indices.exists({index: elasticMigrateMigrationsIndexName});
};

const displayNiceErrorIfNotSetupAndExit = async () => {
  const isSetupCompleted = await checkIfMigrationIndexExists();
  if(!isSetupCompleted) {
    throw new RuntimeError("You must run `elastic-migrate setup <host>` before running this command");
  }
}

const createMigrationsIndex = async () => getClient().indices.create({
  index: elasticMigrateMigrationsIndexName,
  body: {
    mappings: {
      migration: {
        properties: {
          description: {
            type: "text"
          },
          version: {
            type: "date",
            format: "yyyyMMddHHmmss"
          },
          migratedAt: {
            type: "date",
            format: "epoch_millis"
          }
        }
      }
    }
  }
});

module.exports = {
  checkIfMigrationIndexExists,
  createMigrationsIndex,
  exitSuccessfully,
  exitWithError,
  getMigrations,
  getClient,
  setClient,
  elasticMigrateMigrationsIndexName,
  elasticMigrateMigrationsPath,
};
