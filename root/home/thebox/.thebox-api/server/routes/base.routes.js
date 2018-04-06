const Router = require("koa-router")
const router = new Router()
const baseController = require("../controllers/baseController")
const BASE_URL = `${require('../../config').api}`

router.get(`${BASE_URL}/online`, baseController.online)

module.exports = router