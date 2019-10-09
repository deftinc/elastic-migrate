const fs = require('fs');
const util = require('util');
const path = require('path');
const exec = util.promisify(require('child_process').exec);
const program = require('commander');
const mustache = require('mustache');
const {
  exitSuccessfully,
  exitWithError,
  elasticMigrateMigrationsPath
} = require('./elastic-migrate-utils');

let description;

program
  .arguments('<description>')
  .action((descriptionV) => {
    description = descriptionV
  })
  .parse(process.argv);

(async () => {
  if (!description) {
    exitWithError("Error: Must provide a description");
  }
  try {
    const { stdout } = await exec('date -u +%Y%m%d%H%M%S');
    const timeStamp = stdout.trim();
    const fileName = `${timeStamp}_${description}.js`;
    const template = fs.readFileSync(path.join(__dirname, 'elastic-migrate-generate-template.js'), "utf8");
    const filePath = path.join(elasticMigrateMigrationsPath, fileName);
    fs.writeFileSync(filePath, mustache.render(template, {timeStamp, description}));
    exitSuccessfully(`Migration class was generated:\n\t${filePath}`);
  } catch(error) {
    exitWithError(error);
  }
})()
