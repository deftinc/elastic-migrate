const {ElasticMigration} = require('elastic-migrate');

class M20181013140148_create_foo_bar extends ElasticMigration {
  async up() {
    await this.createIndex("bar", {});
    await this.addAlias("foo", "bar");
  }

  async down() {
    await this.removeAlias("foo", "bar");
    await this.removeIndex("bar");
  }
}

module.exports = M20181013140148_create_foo_bar;
