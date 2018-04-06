const fs = require('fs')

const readdir = path => {
  return new Promise(function (resolve, reject) {
    fs.readdir(path, function (error, result) {
      if (error) {
        reject(error)
      } else {
        resolve(result)
      }
    })
  })
}

module.exports = { readdir }