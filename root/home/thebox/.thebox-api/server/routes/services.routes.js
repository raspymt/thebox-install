const Router = require("koa-router")
const router = new Router()
const servicesController = require("../controllers/servicesController")
const jwt = require('../middlewares/jwt')
const BASE_URL = `${require('../../config').api}/services`

router.get(`${BASE_URL}/statuses`, jwt, servicesController.statuses)

router.post(`${BASE_URL}/action`, jwt, servicesController.action)

module.exports = router