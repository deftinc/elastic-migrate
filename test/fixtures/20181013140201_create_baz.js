const {ElasticMigration} = require('elastic-migrate');

class M20181013140201_create_baz extends ElasticMigration {
  async up() {
    await this.createIndex("baz", {});
    await this.addAlias("foo", "baz");
  }

  async down() {
    await this.removeAlias("foo", "baz");
    await this.removeIndex("baz");
  }
}

module.exports = M20181013140201_create_baz;
