const wpa_cli = require('../utils/wpa_cli')
const iw = require('../utils/iw')

const index = async ctx => {
  try {
    const { interface } = ctx.request.header
    let networks = await iw.getNetworks(interface)
    networks.sort((a, b) => {
      return b.signal - a.signal
    })

    const status = await wpa_cli.getStatus(interface)

    ctx.body = {
      networks,
      status
    }
  } catch (error) {
    ctx.status = 500
    ctx.body = {
      error: error
    }
  }
}

module.exports = { index }