const iw = require('wireless-tools/iw')

const getNetworks = async interface => {
  return new Promise((resolve, reject) => {
    iw.scan({ iface : interface, show_hidden : true }, function(err, networks) {
      if (err) {
        reject(err)
      }
      resolve(networks)
    })
  })
}

module.exports = { getNetworks }