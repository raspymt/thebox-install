const Router = require("koa-router")
const router = new Router()
const mediasController = require("../controllers/mediasController")
const jwt = require('../middlewares/jwt')
const BASE_URL = `${require('../../config').api}/medias`

router.get(`${BASE_URL}`, jwt, mediasController.index)

module.exports = router