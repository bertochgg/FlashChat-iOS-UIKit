//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {
    
    let db = Firestore.firestore()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.appName
        navigationItem.hidesBackButton = true
        
        tableView.dataSource = self
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages(){//Method to get the messages from Firebase
        //Nombre de coleccion, metodo para obtener informacion de Firebase, parametros: querySnapshot obtiene la informacion, error son los errores en caso de haber
        db.collection(Constants.FStore.collectionName).order(by: Constants.FStore.dateField).addSnapshotListener { querySnapshot, error in
            self.messages = []//Causes to not duplicate messages
            if let e = error{
                print("There was an issue retrieving data from Firestore, \(e)")
            }else{
                //snapshotDocuments es la variable con la que se accede a los metodos para obtener  la informacion
                if let snapshotDocuments = querySnapshot?.documents{
                    //Ciclo para obtener la data del documento donde se guardan los mensajes
                    for doc in snapshotDocuments{
                        //data es igual a la informacion de cada mensaje y la guarda
                        let data = doc.data()
                        //unwrapp info de la data de firebase
                        if let messageSender = data[Constants.FStore.senderField] as? String, let messageBody = data[Constants.FStore.bodyField] as? String{
                            //creacion de objeto de tipo mensaje para ir guardando la informacion
                            let newMessage = Message(body: messageBody, sender: messageSender)
                            //anexar el objeto a el areglo de messages
                            self.messages.append(newMessage)
                            
                            //Actualizar el tableView
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                
                                //Get the bottom of the last message
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        guard let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email else{
            return
        }
        
        db.collection(Constants.FStore.collectionName).addDocument(data: [
            Constants.FStore.senderField: messageSender,
            Constants.FStore.bodyField: messageBody,
            Constants.FStore.dateField: Date().timeIntervalSince1970
        ]) { error in
            if let e = error{
                print("There was an issue data to firestore, \(e)")
            }else{
                print("Succesfully saved data")
                DispatchQueue.main.async {
                    self.messageTextfield.text = ""
                }
                
            }
        }
        
        
    }
    

    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do{
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        }catch let signOutError as NSError{
            print("Error signing out: %@", signOutError)
        }
    }
}

extension ChatViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! MessageTableViewCell
        cell.messageLabel.text = messages[indexPath.row].body
        
        //This is a message from the current user
        if message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBuble.backgroundColor = UIColor(named: Constants.BrandColors.lightPurple)
            cell.messageLabel.textColor = UIColor(named: Constants.BrandColors.purple)
        }else{
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBuble.backgroundColor = UIColor(named: Constants.BrandColors.purple)
            cell.messageLabel.textColor = UIColor(named: Constants.BrandColors.lightPurple)
        }
        return cell
    }
    
    
}
