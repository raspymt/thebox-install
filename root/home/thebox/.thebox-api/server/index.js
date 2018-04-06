const Koa = require('koa-plus')
const serve = require('koa-static')
const bodyParser = require("koa-bodyparser")
const baseRoutes = require("./routes/base.routes")
const usersRoutes = require("./routes/users.routes")
const servicesRoutes = require("./routes/services.routes")
const networksRoutes = require("./routes/networks.routes")
const mediasRoutes = require("./routes/medias.routes")
const sambaRoutes = require("./routes/samba.routes")
const transmissionRoutes = require("./routes/transmission.routes")

// const PORT = process.env.PORT || require('../config').port
const PORT = 88
const debug = process.env.NODE_ENV !== 'production'

const app = new Koa({
  // body: {
  //   enabled: false
  // },
  // compress: {
  //   enabled: false
  // },
  // cors: {
  //   enabled: false
  // },
  debug: {
    enabled: debug
  },
  // etag: {
  //   enabled: false
  // },
  // helmet: {
  //   enabled: false
  // },
  // json: {
  //   enabled: false
  // },
  logger: {
    enabled: debug
  },
  // requestId: {
  //   enabled: false
  // },
  // responseTime: {
  //   enabled: false
  // }
})

app.use(bodyParser())

app.use(baseRoutes.routes())
app.use(usersRoutes.routes())
// app.use(statusRoutes.routes())
app.use(servicesRoutes.routes())
app.use(networksRoutes.routes())
app.use(mediasRoutes.routes())
app.use(sambaRoutes.routes())
app.use(transmissionRoutes.routes())

// static directory serving
app.use(serve('dist/'))

const server = app.listen(PORT).on("error", err => {
 console.error(err)
})

module.exports = server