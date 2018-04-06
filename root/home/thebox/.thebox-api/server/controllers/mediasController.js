const fs = require('../utils/filesystem')

const index = async ctx => {
  try {
    const mounts = await fs.readdir('/media')
    ctx.body = {
      mounts
    }
  } catch (error) {
    ctx.status = 500
    ctx.body = {
      error: error
    }
  }
}

module.exports = { index }