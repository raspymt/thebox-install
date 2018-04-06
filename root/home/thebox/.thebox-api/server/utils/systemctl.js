const exec = require("child-process-promise").exec

// const enable = async service_name => {
//   try {
//     const service = await _exec('enable ' + service_name)
//     return service.stdout === '' ? true : false
//   } catch(error) {
//     return false
//   }  
// }

// const disable = async service_name => {
//   try {
//     const service = await _exec('disable ' + service_name)
//     return service.stdout === '' ? true : false
//   } catch (error) {
//     return false
//   }

// }

const enableNow = async service_name => {
  try {
    const service = await _exec('enable --now ' + service_name)
    return service.stdout === '' ? true : false
  } catch(error) {
    return false
  }  
}

const disableNow = async service_name => {
  try {
    const service = await _exec('disable --now ' + service_name)
    return service.stdout === '' ? true : false
  } catch (error) {
    return false
  }
}

const start = async service_name => {
  try {
    const service = await _exec('start ' + service_name)
    return service.stderr === '' ? true : false
  } catch (error) {
    return false
  }
}

const stop = async service_name => {
  try {
    const service = await _exec('stop ' + service_name)
    return service.stderr === '' ? true : false
  } catch (error) {
    return false
  }
}

const poweroff = async () => {
  try {
    const service = await _exec('poweroff')
    return service.stderr === '' ? true : false
  } catch (error) {
    return false
  }
}

const reboot = async () => {
  try {
    const service = await _exec('reboot')
    return service.stderr === '' ? true : false
  } catch (error) {
    return false
  }
}

// function restart(service_name) {
//   return _exec("restart " + service_name)
// }

// function daemonReload() {
//   return _exec("daemon-reload")
// }

// const isEnabled = async service_name => {
//   try {
//     const data = await _exec('is-enabled ' + service_name)
//     return data.stdout.indexOf('enabled') !== -1
//   } catch (error) {
//     return false
//   }
// }

const isActive = async service_name => {
  try {
    const data = await _exec('is-active ' + service_name)
    return data.stdout.indexOf('active') !== -1
  } catch (error) {
    return false
  }
}

// const isFailed = async service_name => {
//   try {
//     const data = await _exec('is-failed ' + service_name)
//     return data.stdout.indexOf('failed') !== -1
//   } catch (error) {
//     return false
//   }
// }

function _exec(command) {
   // return exec("sudo systemctl " + command)
  return exec('systemctl ' + command)
}


module.exports = {
  // isEnabled,
  isActive,
  // isFailed,
  // enable,
  // disable,
  enableNow,
  disableNow,
  start,
  stop,
  poweroff,
  reboot
  // restart
}