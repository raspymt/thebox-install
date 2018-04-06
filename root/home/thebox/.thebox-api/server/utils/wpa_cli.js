const wpa_cli = require('wireless-tools/wpa_cli')

const getNetworks = async interface => {
  return new Promise((resolve, reject) => {
    wpa_cli.scan(interface, (err, data) => {
      if (err) {
        reject(err)
      }
      wpa_cli.scan_results(interface, (err, data) => {
        if (err) {
          reject(err)
        }
        resolve(data)
      })
    })
  })
}

const getStatus = async interface => {
  return new Promise((resolve, reject) => {
    wpa_cli.status(interface, function(err, status) {
      if (err) {
        reject(err)
      }
      resolve(status)
    })
  })
}

module.exports = { getNetworks, getStatus }