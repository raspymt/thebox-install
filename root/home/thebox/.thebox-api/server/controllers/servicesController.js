const systemctl = require('../utils/systemctl')

const statuses = async ctx => {
  try {
    const services = JSON.parse(ctx.request.header.services)
    const keys = Object.keys(services)
    const values = Object.values(services)
    let statuses = {}
    for (var i = keys.length - 1; i >= 0; i--) {
      statuses[keys[i]] = await systemctl.isActive(values[i].service)
    }
    ctx.body = {
      statuses
    }
  } catch (error) {
    ctx.status = 500
    ctx.body = {
      error: error
    }
  }
}

const action = async ctx => {
  try {
    const { service, action } = ctx.request.header
    ctx.body = {
      data: {
        success: await systemctl[action](service)
      }
    }
  } catch(e) {
    ctx.status = 500
    ctx.body = {
      error: error
    }
  }
}

module.exports = { statuses, action }