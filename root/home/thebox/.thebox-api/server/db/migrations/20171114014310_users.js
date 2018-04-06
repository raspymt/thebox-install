exports.up = function(knex, Promise) {
  return knex.schema.createTableIfNotExists('users', table => {
    table.increments('id');
    table.string('username').notNullable().unique();
    table.string('password').notNullable();
    table.string('role').notNullable();
  });
};

exports.down = function(knex, Promise) {
  return knex.schema.dropTableIfExists('users');
};
