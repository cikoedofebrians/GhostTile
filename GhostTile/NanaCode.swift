//
//  NanaCode.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 10/06/25.
//

import UIKit
import AVFoundation
import Vision
import SwiftUI

class NoddingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // session -> pengambilan vid
    private let session = AVCaptureSession()
    // handle output berupa frame video (img per durasi yang diambil terus) dari video
    private let videoOutput = AVCaptureVideoDataOutput()
    // menampilkan preview (cam di ui)
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // status player (nod to start, ready)
    private let player1Label = UILabel()
    private let player2Label = UILabel()
    
    private var nodInProgress: [Bool] = [false, false]
    private var isReady: [Bool] = [false, false]
    private var previousNoseY: [CGFloat?] = [nil, nil]
    
    private var hasNavigated = false
    
    private var baselineNoseY: [CGFloat?] = [nil, nil]
    private enum NodState {
        case idle, noddingDown, noddingUp
    }
    private var nodState: [NodState] = [.idle, .idle]

    
    // function ni tuh dipanggil pas app baru dibuka dan load ui -> set camera & uinya
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    

    private func setupCamera() {
        // resolusi high quality
        session.sessionPreset = .high
        // cari camera depan & buat input camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to access front camera")
            return
        }
        
        // if can input -> nambah input ke sesi
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // delegate untuk terima frame dari kamera di queue terpisah
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        // add output (video frame) ke session
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        
        // atur orientasi landscape right (basically diforce ig soalnya di plist ga works for vid)
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // atur kamera depan biar gak kebalik mirrored & orientasi bisa tetep landscape ga muter2
        if let connection = previewLayer.connection {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .landscapeRight
            }
        }
        
        view.layer.addSublayer(previewLayer)
        session.startRunning()
    }
    
    // set up label doang
    private func setupUI() {
        [player1Label, player2Label].forEach { label in
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // nambahin label ke tampilan, atur posisi
        view.addSubview(player1Label)
        view.addSubview(player2Label)
        
        NSLayoutConstraint.activate([
            player1Label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            player1Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            player2Label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            player2Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        updateLabels()
    }
    
    // status udah nod atau blom
    private func updateLabels() {
        player1Label.text = isReady[0] ? "Player 1: Ready ✅" : "Player 1: Nod to start!"
        player2Label.text = isReady[1] ? "Player 2: Ready ✅" : "Player 2: Nod to start!"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // get img from frame
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // request detect face landmark
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNFaceObservation] else { return }
            

            // for 2 players -> proses max 2 muka
            let sortedFaces = observations
                .sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
                .prefix(2)
            for face in sortedFaces {
                print(face.boundingBox.minX)
            }

            for (index, face) in sortedFaces.enumerated() {

                guard let nose = face.landmarks?.nose else { continue }
                
                // Ambil Y hidung rata-rata
                let noseY = nose.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(nose.pointCount)
                
                // Atur baseline jika belum ada
                if self.baselineNoseY[index] == nil {
                    self.baselineNoseY[index] = noseY
                }
                
                guard let baselineY = self.baselineNoseY[index] else { continue }
                let deltaFromBaseline = noseY - baselineY
                
                switch self.nodState[index] {
                case .idle:
                    // Deteksi kepala mulai turun
                    if deltaFromBaseline < -0.04 {
                        self.nodState[index] = .noddingDown
                    }
                    
                case .noddingDown:
                    // Deteksi kepala kembali naik → berarti nod lengkap
                    if deltaFromBaseline > -0.015 {
                        self.nodState[index] = .noddingUp
                    }
                    
                case .noddingUp:
                    self.isReady[index] = true
                    self.nodState[index] = .idle
                    self.baselineNoseY[index] = nil  // reset baseline supaya bisa nod lagi nanti kalau perlu
                }
            }


//            DispatchQueue.main.async {
//                self.updateLabels()
//                
//                // if both players are ready then stop camera & pindah ke page game (masih dummy)
//                if self.isReady[0], self.isReady[1], !self.hasNavigated {
//                    self.hasNavigated = true
//                    self.session.stopRunning()
//                    
//                    let nextVC = BlankViewController()
//                    nextVC.modalPresentationStyle = .fullScreen
//                    self.present(nextVC, animated: true, completion: nil)
//                }
//            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored)
        try? handler.perform([request])
    }
}

