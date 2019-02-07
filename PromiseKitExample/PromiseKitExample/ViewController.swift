//
//  ViewController.swift
//  PromiseKitExample
//
//  Created by Dimitar Stefanovski on 2/6/19.
//  Copyright © 2019 Dimitar Stefanovski. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit

class ViewController: UIViewController {
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    //5000 photos json data
    private let photosURL = "https://jsonplaceholder.typicode.com/photos"
    private var photos: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundQueue = DispatchQueue.global(qos: .background)
        
        firstly {
            showLoader()
        }.then(on: backgroundQueue) {
            self.fetchJSON()
        }.then(on: backgroundQueue) { (photos) in
            self.downloadPhotos(photos: Array(photos.prefix(40)))
        }.done(on: DispatchQueue.main, flags: nil) { _ in
            self.hideLoader()
            self.photoCollectionView.reloadData()
        }.catch { (error) in
                print(error.localizedDescription)
        }
        
        
        
    }
    
    private func showLoader() -> Guarantee<Void> {
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
        return Guarantee()
    }
    
    private func hideLoader() -> Guarantee<Void> {
        self.activityIndicator.stopAnimating()
        return Guarantee()
    }
    
    
    private func fetchJSON() -> Promise<[Photo]> {
        return Promise { seal in
            Alamofire.request(photosURL, method: .get).validate().responseData { (data) in
                guard let data = data.result.value else {
                    seal.reject(PhotoError.ConvertToData)
                    return
                }
                guard let photos = try? JSONDecoder().decode([Photo].self, from: data) else {
                    seal.reject(PhotoError.PhotoDecoding)
                    return
                }
                seal.fulfill(photos)
            }
        }
    }
    
    private func downloadPhotos(photos: [Photo]) -> Promise<[UIImage]> {
        return Promise { seal in
            var count = 0
            for photo in photos {
                guard let photoUrl = URL(string: photo.url) else {
                    seal.reject(PhotoError.downloadPhotoUrl)
                    return
                }
                guard let photoData = try? Data(contentsOf: photoUrl) else {
                    seal.reject(PhotoError.downloadPhotoConvertToData)
                    return
                }
                guard let photoImage = UIImage(data: photoData) else {
                    seal.reject(PhotoError.downloadPhotoConvertToUIImage)
                    return
                }
                self.photos.append(photoImage)
                count+=1
                print("Finished downloading photo: " + String(count))
                
            }
            print("Finished downloading \(self.photos.count) photos")
            seal.fulfill(self.photos)
        }
    }
    
    

}


enum PhotoError: Error {
    case ConvertToData
    case PhotoDecoding
    case downloadPhotoUrl
    case downloadPhotoConvertToData
    case downloadPhotoConvertToUIImage
}


struct Photo: Codable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoCell = self.photoCollectionView.dequeueReusableCell(withReuseIdentifier: "photo", for: indexPath) as! PhotoCollectionViewCell
        photoCell.photo.image = self.photos[indexPath.row]
        return photoCell
    }
    
    
}
