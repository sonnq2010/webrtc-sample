const express = require('express')
const WebSocket = require('ws')
const app = express()
const shortid = require('shortid')

app.set('view engine', 'ejs')
app.get('/', ((req, res) => {
    res.render('index')
}))

let port = process.env.PORT || 8080
let httpServer = app.listen(port, () => console.log(`http://localhost:${port}`))
let ws = new WebSocket.Server({server: httpServer}, () => {
    console.log('WS server is running')
})

ws.on('connection', client => {

    client.id = shortid.generate()
    console.log(`Client ${client.id} connected`)

    client.send(JSON.stringify({
        type:'id',
        data: client.id
    }))
    client.send(JSON.stringify({type: 'text-important', data: `Có tất cả ${ws.clients.size} user đang online`}))
    ws.clients.forEach(c => {
        if (c !== client) {
            c.send(JSON.stringify({type: 'text-important', data: `User ${client.id} đã tham gia cuộc trò chuyện`}))
        }
    })

    client.on('error', e => {
        console.log('Client error')
        console.log(e)
    })

    client.on('message', message => {
        console.log(`Client ${client.id}: ${message}`)
        ws.clients.forEach(c => {
            if (c !== client) {
                c.send(message)
            }
        })
    })

    client.on('close', () => {
        console.log(`Client ${client.id} disconnected`)
        ws.clients.forEach(c => {
            if (c !== client) {
                c.send(JSON.stringify({type: 'text-important', data: `user ${client.id} đã ngắt kết nối`}))
            }
        })
    })
});

ws.on('error', e => {
    console.log('WS Server error')
    console.log(e)
})