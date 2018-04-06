const env = process.env.NODE_ENV || "development"
const config = require("../../knexfile")[env]
const knex = require("knex")(config)
const jsonwebtoken = require('jsonwebtoken')
const atob = require('atob')
const bcrypt    = require('bcrypt')

const index = async ctx => {
  try {
    const users = await knex("users").select()
    ctx.body = {
      data: users
    }
  } catch (error) {
    ctx.status = 401
    ctx.body = {
      error: error
    }
  }
}

const show = async ctx => {
  try {
    const { id } = ctx.params
    const user = await knex("users")
      .select()
      .where({ id })
    if (!user.length) {
      throw new Error("The requested resource does not exists")
    }
    ctx.body = {
      data: user
    }
  } catch (error) {
    ctx.status = 404
    ctx.body = {
      error: error
    }
  }
}

const create = async ctx => {
  try {
    const { body } = ctx.request
    // hassh password with bcrypt
    const hash = await bcrypt.hash(body.password, 12)
    if (!hash) {
      throw new Error("Error during password hash")
    }
    body.password = hash
    const user = await knex("users").insert(body)
    if (!user.length) {
      throw new Error("The resource already exists")
    }
    ctx.status = 201
    ctx.set("Location", `${ctx.request.URL}/${user[0]}`)
    ctx.body = {
      data: user
    }
  } catch (error) {
    if(error.code === 'SQLITE_CONSTRAINT') {
      ctx.status = 409
    } else {
      ctx.status = 500
    }
    ctx.body = {
      error: error
    }      
  }
}

const login = async ctx => {
  try {
    const credentials = atob(ctx.request.header.authorization.replace('Basic ', '')).split(':')
    if (!credentials.length || credentials.length < 2) {
      throw new Error("You must provide a username and password")
    }

    const user = await knex("users")
      .select()
      .where({ username: credentials[0] })
    if (!user.length) {
      throw new Error("User not found")
    }

    // compare password with bcrypt
    const comp = await bcrypt.compare(credentials[1], user[0].password)
    if (comp === false) {
      throw new Error("Username and password do not match")
    } else if (comp === true) {
      const token = await jsonwebtoken.sign(
          {
            id: user[0].id,
            username: user[0].username,
            role: user[0].role
          },
          require('../../config').secret,
          { 
            expiresIn: '24h'
            // expiresIn: '10s'
          }
        )
      if(!token) {
        throw new Error('Token Error')
      }
      ctx.status = 201
      ctx.body = {
        token: token
      }      
    } else {
      throw new Error("Error during password hash")
    }
  } catch (error) {
    if(error.toString() === 'Error: Error during password hash') {
      ctx.status = 500
    } else {
      ctx.status = 401
    }
    ctx.body = {
      error: error
    }
  }
}

const verify = async ctx => {
  ctx.body = {
    success: true,
    // token: ctx.request.header.authorization.replace('Bearer ', '')
  }
}

const update = async ctx => {
  try {
    const credentials = atob(ctx.request.body.credentials.replace('UpdateUser ', '')).split(':')
    // hash password with bcrypt
    const hash = await bcrypt.hash(credentials[1], 12)
    if (!hash) {
      throw new Error("Error during password hash")
    }
    const { id } = ctx.params
    const result = await knex("users")
      .where({ id })
      .update({
        username: credentials[0],
        password: hash
      })
    
    if (result !== 1) {
      throw new Error("Cannot update user")
    }

    ctx.status = 200
    ctx.body = {
      success: result === 1
    }
  } catch (error) {
    ctx.status = 500
    ctx.body = {
      error: error
    }
  }
}

module.exports = { index, show, create, login, verify, update }
