const { exec } = require('child_process')
const systemctl = require('./systemctl')

const updateConfigCredentials = (user, password) => {
  return new Promise(async (resolve, reject) => {
    const transmissionConfigFile = '/home/thebox/.config/transmission-daemon/settings.json'
    const isActive = await systemctl.isActive('transmission')
    let transmissionService = null
    if (isActive === true) {
      // must stop service before changing password
      transmissionService = await systemctl.stop('transmission')
    }

    if (transmissionService === true || transmissionService === null) {
      exec(`sed -ie 's/   "rpc-username": .*/   "rpc-username": "${username}",/' ${transmissionConfigFile} && sed -ie 's/   "rpc-password": .*/   "rpc-password": "${password}",/' ${transmissionConfigFile}`, (error, stdout, stderr) => {
        if (isActive === true) {
          // must start service after changing password
          systemctl.start('transmission')
        }
        if (error) {
          reject(stderr)
        }
        resolve(stdout)
      })
    } else {
      reject('Error during credentials update')
    }
  })
}

module.exports = { updateConfigCredentials }