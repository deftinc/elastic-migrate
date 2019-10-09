const {ElasticMigration} = require('elastic-migrate');

class M20181013140207_remove_bar extends ElasticMigration {
  async up() {
    await this.removeIndex("bar");
  }

  async down() {
    await this.createIndex("bar", {});
    await this.addAlias("foo", "bar");
  }
}

module.exports = M20181013140207_remove_bar;
