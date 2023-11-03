//
//  ContentView.swift
//  FirebaseAPI_SwiftUI
//
//  Created by 이성현 on 2023/10/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore


struct ContentView: View {
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Test"){
                FirebaseManager.addData()
            }
        }
        .padding()
    }
}

class FirebaseManager {
    
    static let db = Firestore.firestore()
    
    // MARK: - 데이터 추가
    static func addData() {
        // users 라는 컬렉션에 문서를 추가
        // 문서추가(ID 가 자동으로 설정됨)
        // 자동으로 생성된 ID는 정렬을 지원하지 않는다
        var ref: DocumentReference? = nil
        ref = db.collection("users").addDocument(data: [
            "first": "Alan",
            "middle": "Mathison",
            "last": "Turing",
            "born": 1912
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    // MARK: - 데이터 읽기(전체데이터)
    static func getAllData() {
        db.collection("users").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
        
    }
    
    // MARK: - 데이터 읽기(특정문서)
    static func getData() {
        let docRef = db.collection("cities").document("SF")

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
            } else {
                print("Document does not exist")
            }
        }
    }
    
    // MARK: - 데이터 설정
    // 단일 문서를 만들거나 덮어쓰는 경우 set() 메서드를 사용
    // 컬렉션과 문서이름이 일치하는경우 데이터가 덮어씌워짐
    static func setData() {
        db.collection("cities").document("LA").setData([
            "name": "Los Angeles",
            "state": "CA",
            "country": "USA2222"
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    // MARK: - 데이터 업데이트
    // 문서가 존재하지 않는경우 업데이트하지 않는다
    static func updateData() {
        let washingtonRef = db.collection("cities").document("LA")
        washingtonRef.updateData([
            "state": "DC",
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    // MARK: - 서버 타임스탬프
    // lastUpdated 라는 필드에 서버에서 수신하는 시간을 저장해줌
    static func setverTimeStamp() {
        db.collection("cities").document("LA").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    // MARK: - 중첩된 데이터참조
    // 문서내부에 배열이 있는경우
    
    static func referenceDataField() {
        // Create an initial document to update.
        let frankDocRef = db.collection("users").document("frank")
        frankDocRef.setData([
            "name": "Frank",
            "favorites": [ "food": "Pizza", "color": "Blue", "subject": "recess" ],
            "age": 12
            ])

        // 데이터를 가져옴
        db.collection("users").document("frank").updateData([
            "age": 13,
            "favorites.color": "Red" // .으로 중첩데이터를 참조가능
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    // MARK: - 트랜잭션
    // 트랜잭션: 1개 이상의 문서에 대한 읽기 및 쓰기 작업의 집합
    // 동시에 여러데이터에 접근할때 데이터의 수정이 완료되기까지 시도한다
    // 동시에 한개의 데이터에 접근할때 데이터의 안정성을 보장하기 위해서라고 이해함
    // 트랜잭션에 실패할떄 여러번 시도를 할 수 있기때문에 트랜잭션 함수내부에서 UI로직을 실행하면 안된다.
    
    static func transaction() {
        let sfReference = db.collection("cities").document("SF")
        
        // 트랜잭션 함수를 만든다
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let sfDocument: DocumentSnapshot
            // 읽기함수
            do {
                try sfDocument = transaction.getDocument(sfReference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldPopulation = sfDocument.data()?["population"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(sfDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }

            // Note: this could be done without a transaction
            //       by updating the population using FieldValue.increment()
            let newPopulation = oldPopulation + 1
            guard newPopulation <= 1000000 else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Population \(newPopulation) too big"]
                )
                errorPointer?.pointee = error
                return nil
            }
            // 데이터를 업데이트
            transaction.updateData(["population": newPopulation], forDocument: sfReference)
            return newPopulation
        }) { (object, error) in
            // 트랜잭션 결과를 클로저함수로 반환받는다.
            if let error = error {
                print("Error updating population: \(error)")
            } else {
                print("Population increased to \(object!)")
            }
        }
    }
    
    // MARK: - 데이터 삭제
    // 문서를 삭제해도 하위 컬렉션의 문서를 삭제하지 않는다
    // 전체컬렉션을 삭제하는 경우 문서를 조금씩 나눠서 삭제하면 메모리 부족을 방지할 수 있다.
    // 대용량의 데이터삭제는 클라이언트보다 서버환경에서 삭제를 추천
    
    static func deleteData() {
        db.collection("cities").document("DC").delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    // MARK: - 실시간 데이터수신
    // addSnapshot() 메서드가 호출되면 현재 콘텐츠로 문서 스냅샷이 생성된다.
    static func snapShot() {
        db.collection("cities").document("SF")
            .addSnapshotListener { documentSnapshot, error in
              guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
              }
              guard let data = document.data() else {
                print("Document data was empty.")
                return
              }
              print("Current data: \(data)")
            }
    }
}

#Preview {
    ContentView()
}
