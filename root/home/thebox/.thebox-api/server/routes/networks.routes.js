const Router = require("koa-router")
const router = new Router()
const networksController = require("../controllers/networksController")
const jwt = require('../middlewares/jwt')
const BASE_URL = `${require('../../config').api}/networks`

router.get(`${BASE_URL}`, jwt, networksController.index)

module.exports = router