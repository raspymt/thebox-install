// test/users.routes.test.js
// Configure the environment and require Knex
const env = process.env.NODE_ENV || "development";
const config = require("../knexfile")[env];
const server = require("../server/index");
const knex = require("knex")(config);
const PATH = "/api/v1/users";

// Require and configure the assertion library
const chai = require("chai");
const should = chai.should();
const chaiHttp = require("chai-http");
chai.use(chaiHttp);

// Rollback, commit and populate the test database before each test
describe("routes: users", () => {
  beforeEach(() => {
    return knex.migrate
      .rollback()
      .then(() => {
        return knex.migrate.latest();
      })
      .then(() => {
        return knex.seed.run();
      });
  });

  // Rollback the migration after each test
  afterEach(() => {
    return knex.migrate.rollback();
  });


  describe(`GET ${PATH}`, () => {
    it("should return all the resources", done => {
      chai
        .request(server)
        .get(`${PATH}`)
        .end((err, res) => {
          should.not.exist(err);
          res.status.should.eql(200);
          res.type.should.eql("application/json");
          res.body.data.length.should.eql(3);
          res.body.data[0].should.include.keys("id", "username", "password", "admin");
          done();
        });
    });
  });

  describe(`GET ${PATH}/:id`, () => {
    it("should return a single resource", done => {
      chai
        .request(server)
        .get(`${PATH}/1`)
        .end((err, res) => {
          should.not.exist(err);
          res.status.should.eql(200);
          res.type.should.eql("application/json");
          res.body.data.length.should.eql(1);
          res.body.data[0].should.include.keys("id", "username", "password", "admin");
          done();
        });
    });
    it("should return an error when the requested user does not exists", done => {
      chai
        .request(server)
        .get(`${PATH}/9999`)
        .end((err, res) => {
          should.exist(err);
          res.status.should.eql(404);
          res.type.should.eql("application/json");
          res.body.error.should.eql("The requested resource does not exists");
          done();
        });
    });
  });

  describe(`POST ${PATH}`, () => {
    it("should return the newly added resource identifier alongside a Location header", done => {
      chai
        .request(server)
        .post(`${PATH}`)
        .send({
          username: "A test user",
          password: "thepassword",
          admin: false
        })
        .end((err, res) => {
          should.not.exist(err);
          res.status.should.eql(201);
          res.should.have.header("Location");
          res.type.should.eql("application/json");
          res.body.data.length.should.eql(1);
          res.body.data[0].should.be.a("number");
          done();
        });
    });
    it("should return an error when the resource already exists", done => {
      chai
        .request(server)
        .post(`${PATH}`)
        .send({
          username: "joe",
          password: "joe",
          admin: false
        })
        .end((err, res) => {
          should.exist(err);
          res.status.should.eql(409);
          res.type.should.eql("application/json");
          res.body.error.should.eql("The resource already exists");
          done();
        });
    });
  });

});