//
//  PushNotification.swift
//  Multipeer-PegaPega
//
//  Created by Arthur Dos Reis on 15/11/23.
//

import Foundation
import SwiftUI
import CloudKit

class PushNotifications: ObservableObject {
    
    func initCloud(){
        requestNotificationPermission()
        subscribeToNotifications()
        sendNotification()
    }
    
    func requestNotificationPermission() {
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { data, error in
            if let error = error {
                print(error)
            } else if data{
                DispatchQueue.main.async{
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permissions failure.")
                
            }
        }
        
    }
    
    func subscribeToNotifications(){
        let predicate = NSPredicate(value: true)
        let subscripton = CKQuerySubscription(recordType: "PegaPega", predicate: predicate, subscriptionID: "pega_pega_notification", options: .firesOnRecordCreation)
        
        let notification = CKSubscription.NotificationInfo()
        notification.title = "Uma nova partida está sendo criada!"
        notification.alertBody = "Abra o jogo para partipar da partida."
        notification.soundName = "default"
        
        subscripton.notificationInfo = notification
        
        CKContainer.default().publicCloudDatabase.save(subscripton) { data , error in
            if let error = error{
                print(error)
            } else {
                print("Successfully subscribed to notifications!")
            }
        }
    }
    
    func sendNotification(){
        print("Enviou")
        let extractedExpr = CKRecord(recordType: "PegaPega")
        let newData = extractedExpr
        newData["Teste"] = "NewData"
        saveItem(newData)
    }
    
    func saveItem(_ record: CKRecord){
        CKContainer.default().publicCloudDatabase.save(record) { data, error in
            if let error = error{
                print(error)
            }else{
                print("Record saved!")
            }
        }
    }
    
}

struct TesteView: View {
    
    @StateObject private var cloudPush = PushNotifications()
    
    var body: some View {
        VStack{
            
            Button("Teste Notification"){
                cloudPush.sendNotification()
            }
            Button("Subscription"){
                cloudPush.subscribeToNotifications()
            }
            Button("Permission"){
                cloudPush.requestNotificationPermission()
                
            }
            
        
        }
    }
}

#Preview {
    TesteView()
}
