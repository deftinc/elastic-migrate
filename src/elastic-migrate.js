#!/usr/bin/env node
const program = require('commander');
const fs = require('fs');

// let command, host;

program
  .command('generate <description>', 'generate a migration with the given description')
  .command('up [version]', 'migrate up to a version, latest version by default')
  .command('down [version]', 'migrate down to a version, down one version by default')
  .command('list', 'list migration versions local and host')
  .command('setup', 'one-time setup to have track schema on host')
  .parse(process.argv);
