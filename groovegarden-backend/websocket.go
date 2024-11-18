// package main

// import (
// 	"net/http"
// 	"sync"
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 

// 	"github.com/gorilla/websocket"
// )

// var clients = make(map[*websocket.Conn]bool)
// var broadcast = make(chan Message)
// var upgrader = websocket.Upgrader{
// 	CheckOrigin: func(r *http.Request) bool {
// 		return true
// 	},
// }

// var mutex sync.Mutex

// type Message struct {
// 	Type string      `json:"type"`
// 	Data interface{} `json:"data"`
// }

// func handleConnections(w http.ResponseWriter, r *http.Request) {
// 	// Upgrade initial GET request to a WebSocket
// 	ws, err := upgrader.Upgrade(w, r, nil)
// 	if err != nil {
// 		http.Error(w, "Could not open websocket connection", http.StatusBadRequest)
// 		return
// 	}
// 	defer ws.Close()

// 	mutex.Lock()
// 	clients[ws] = true
// 	mutex.Unlock()

// 	// Listen for incoming messages
// 	for {
// 		var msg Message
// 		err := ws.ReadJSON(&msg)
// 		if err != nil {
// 			mutex.Lock()
// 			delete(clients, ws)
// 			mutex.Unlock()
// 			break
// 		}
// 	}
// }

// func handleMessages() {
// 	for {
// 		msg := <-broadcast
// 		mutex.Lock()
// 		for client := range clients {
// 			err := client.WriteJSON(msg)
// 			if err != nil {
// 				client.Close()
// 				delete(clients, client)
// 			}
// 		}
// 		mutex.Unlock()
// 	}
// }

// func notifyClients(messageType string, data interface{}) {
// 	broadcast <- Message{Type: messageType, Data: data}
// }
