const atob = require('atob')
const { updateSambaPassword } = require('../utils/samba')

const updatePassword = async ctx => {
  try {
    const password = atob(ctx.request.body.credentials.replace('UpdatePassword ', ''))
    const result = await updateSambaPassword('thebox', password)
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

module.exports = { updatePassword }