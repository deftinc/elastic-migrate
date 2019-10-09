const {ElasticMigration} = require('elastic-migrate');

class M20181013140224_remove_foo extends ElasticMigration {
  async up() {
    await this.removeAlias("foo", "baz");
  }

  async down() {
    await this.addAlias("foo", "baz");
  }
}

module.exports = M20181013140224_remove_foo;
