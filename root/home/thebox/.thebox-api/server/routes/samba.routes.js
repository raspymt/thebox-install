const Router = require("koa-router")
const router = new Router()
const sambaController = require("../controllers/sambaController")
const jwt = require('../middlewares/jwt')
const BASE_URL = `${require('../../config').api}/samba`

router.post(`${BASE_URL}/update/password`, jwt, sambaController.updatePassword)

module.exports = router