const atob = require('atob')
const { updateConfigCredentials } = require('../utils/transmission')

const updateCredentials = async ctx => {
  try {
    const credentials = atob(ctx.request.body.credentials.replace('UpdateCredentials ', '')).split(':')
    const result = await updateConfigCredentials(credentials[0], credentials[1])
    ctx.body = {
      success: true
    }
  } catch (error) {
    ctx.status = 500
    ctx.body = {
      error: error
    }
  }
}

module.exports = { updateCredentials }