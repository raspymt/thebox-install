const Router = require("koa-router")
const router = new Router()
const usersController = require("../controllers/usersController")
const jwt = require('../middlewares/jwt')
const BASE_URL = `${require('../../config').api}/users`

// router.get(`${BASE_URL}`, jwt, usersController.index)
// router.get(`${BASE_URL}/:id`, jwt, usersController.show)

// router.post(`${BASE_URL}`, jwt, usersController.create)
router.post(`${BASE_URL}/verify`, jwt, usersController.verify)
router.post(`${BASE_URL}/login`, usersController.login)

router.put(`${BASE_URL}/:id`, jwt, usersController.update)

module.exports = router
