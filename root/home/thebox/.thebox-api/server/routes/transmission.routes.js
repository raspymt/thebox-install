const Router = require("koa-router")
const router = new Router()
const transmissionController = require("../controllers/transmissionController")
const jwt = require('../middlewares/jwt')
const BASE_URL = `${require('../../config').api}/transmission`

router.post(`${BASE_URL}/update/credentials`, jwt, transmissionController.updateCredentials)

module.exports = router