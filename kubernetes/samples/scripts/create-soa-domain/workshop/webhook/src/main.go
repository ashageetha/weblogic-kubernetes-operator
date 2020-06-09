package main

import (
    "fmt"
    "log"
    "net/http"
    "net/http/httputil"
)

func webhook(w http.ResponseWriter, r *http.Request){
    if reqDump, err := httputil.DumpRequest(r,true); err != nil {
      log.Println(err)
    } else {
      log.Println(string(reqDump))
      fmt.Fprintf(w, string(reqDump))  
    }
}


func handleRequests() {
    http.HandleFunc("/webhook", webhook)
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func main() {
    handleRequests()
}
