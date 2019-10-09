const {ElasticMigration} = require('elastic-migrate');

class M{{timeStamp}}_{{description}} extends ElasticMigration {
  async up() {
    // await this.createIndex(INDEX_NAME, SETTINGS)
    // await this.removeIndex(INDEX_NAME)
    // await this.addAlias(ALIAS_NAME, INDEX_NAME)
    // await this.removeAlias(ALIAS_NAME, INDEX_NAME)
  }

  async down() {}
}

module.exports = M{{timeStamp}}_{{description}};
