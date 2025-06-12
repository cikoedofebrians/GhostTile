//
//  CameraManager.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 10/06/25.
//


import SwiftUI
import Vision
import AVFoundation

enum RollSide: Hashable, Equatable {
    case left
    case right
    case none
}

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var faceRollSide: [RollSide] = []
    @Published var lastRollSide: RollSide = .none
    
    let session = AVCaptureSession()
    
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue")
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        
        session.addInput(input)
        session.connections.first?.videoOrientation = .landscapeRight
        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            session.addOutput(videoOutput)
        }
        startSession()
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let results = request.results as? [VNFaceObservation] {
                let sortFaceRolls = results.sorted { $0.boundingBox.origin.x > $1.boundingBox.origin.x }
                let limitFaceRolls = sortFaceRolls.prefix(2)
                
                let faceRolls = limitFaceRolls.map { face in
                    if let roll = face.roll {
                        let rollInDegrees = roll.doubleValue * (180.0 / .pi)
                        if rollInDegrees < -20 {
                            return RollSide.left
                        } else if rollInDegrees > 20 {
                            return RollSide.right
                        }
                    }
                    return .none
                }
                DispatchQueue.main.async  {
                    self.faceRollSide = faceRolls
                    if faceRolls.count == 2 {
                        if faceRolls[0] == faceRolls[1] && self.lastRollSide != faceRolls[0] {
                            self.lastRollSide = faceRolls[0]
                        }
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .down, options: [:])
        
        try? handler.perform([request])
    }
}
