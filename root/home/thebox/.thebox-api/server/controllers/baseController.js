const online = async ctx => {
  try {
    ctx.body = {
      online: true
    }
  } catch (error) {
    ctx.status = 500
    ctx.body = {
      error: error
    }    
  }
}

module.exports = { online }