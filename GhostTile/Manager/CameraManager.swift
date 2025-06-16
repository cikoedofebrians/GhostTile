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

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    var delegate: GameDelegate?
    var faceRollSide: [RollSide] = []
    
    @Published var faceNods: [Bool] = []
    private var initialNodsPitch: [Double] = []
    
    private var previousEyeStates: [Bool] = [false, false]
    
    
    func adjustCharAnimation(first: RollSide, second: RollSide) {
        if first == .none && second == .right || first == .right && second == .none {
            delegate?.rightAnimation()
        } else if first == .none && second == .left || first == .left && second == .none {
            delegate?.leftAnimation()
        } else if first == .right && second == .left {
            delegate?.crashAnimation()
        } else if first == .left && second == .right {
            delegate?.crashInverseAnimation()
        } else if first == .none && second == .none {
            delegate?.idleAnimation()
        }
    }
    
    var lastRollSide: RollSide = .none {
        didSet {
            switch lastRollSide {
            case .left:
                self.delegate?.moveLeft()
            case .right:
                self.delegate?.moveRight()
            case .none:
                break
            }
        }
    }
    
    let session = AVCaptureSession()
    
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue")
    
    override init() {
        super.init()
        self.delegate?.idleAnimation()
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
        let faceRectanglesRequest = VNDetectFaceRectanglesRequest { request, error in
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
                
                if self.faceNods.count != limitFaceRolls.count {
                    DispatchQueue.main.async {
                        self.initialNodsPitch = []
                        self.faceNods = Array(repeating: false, count: limitFaceRolls.count)
                    }
                }
                
                if self.faceNods.count == 2 {
                    for (index, face) in limitFaceRolls.enumerated() {
                        if let pitch = face.pitch {
                            let pitchInDegrees = pitch.doubleValue * (180.0 / .pi)
                            if self.initialNodsPitch.count < 2 {
                                self.initialNodsPitch.append(pitchInDegrees)
                            } else if self.initialNodsPitch.count == self.faceNods.count {
                                if pitchInDegrees - self.initialNodsPitch[index] > 10 && !self.faceNods[index] {
                                    DispatchQueue.main.async {
                                        self.faceNods[index] = true
                                        
                                       
                                        self.delegate?.nodDetected(playerIndex: index) // changed yeaa
                                       
                                    }
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async  {
                    if faceRolls.count == 2 {
                        if self.faceRollSide.count == 2 && (faceRolls[0] != self.faceRollSide[0] || faceRolls[1] != self.faceRollSide[1]) {
                            self.adjustCharAnimation(first: faceRolls[0], second: faceRolls[1])
                        }
                        self.faceRollSide = faceRolls
                        if faceRolls[0] == faceRolls[1] && self.lastRollSide != faceRolls[0] {
                            self.lastRollSide = faceRolls[0]
                        }
                    }
                }
            }
        }
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { request, error in
            if let results = request.results as? [VNFaceObservation], results.count >= 2 {
                let limitFaceRolls =  results.prefix(2)
                var blinkStates: [Bool] = []
                
                for face in limitFaceRolls {
                    guard let landmarks = face.landmarks,
                          let leftEye = landmarks.leftEye,
                          let rightEye = landmarks.rightEye else {
                        blinkStates.append(false)
                        continue
                    }
                    
                    let leftClosed = self.isEyeClosed(leftEye)
                    let rightClosed = self.isEyeClosed(rightEye)
                    blinkStates.append(leftClosed && rightClosed)
                }
                
                
                while blinkStates.count < 2 {
                    blinkStates.append(false)
                }
                
                for (index, _) in blinkStates.enumerated() {
                    if blinkStates[index] != self.previousEyeStates[index] {
                        DispatchQueue.main.async {
                            self.delegate?.blinkDetected()
                        }
                    }
                }
                
                self.previousEyeStates = blinkStates
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .down, options: [:])
        
        try? handler.perform([faceLandmarksRequest, faceRectanglesRequest])
    }
    
    private func isEyeClosed(_ eye: VNFaceLandmarkRegion2D) -> Bool {
        guard eye.pointCount >= 6 else { return false }
        let points = eye.normalizedPoints
        let vertical = distance(points[1], points[5])
        let horizontal = distance(points[0], points[3])
        let ratio = vertical / horizontal
        return ratio < 0.05
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx*dx + dy*dy)
    }
}
