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
    
    @Published var playerCount: Int = 0
    @Published var playerOneNodded = false
    @Published var playerTwoNodded = false
    
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue")
    
    private var baselineNoseY: [Int: CGFloat] = [:]
    private var nodState: [Int: NodState] = [0: .idle, 1: .idle]
    private var hasNodded: [Int: Bool] = [:]
    
    private enum NodState {
        case idle
        case noddingDown
        case noddingUp
    }
    
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
        
        let faceRectanglesRequest = VNDetectFaceRectanglesRequest { request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                DispatchQueue.main.async {
                    self.playerCount = 0
                }
                return
            }
            
            let sortedFaces = results.sorted { $0.boundingBox.origin.x > $1.boundingBox.origin.x }
            let limitedFaces = sortedFaces.prefix(2)
            
            let faceRolls = limitedFaces.map { face -> RollSide in
                if let roll = face.roll {
                    let rollInDegrees = roll.doubleValue * (180.0 / .pi)
//                    print("DEBUG: Detected face roll = \(rollInDegrees)°")
                    if rollInDegrees < -20 {
                        return .left
                    } else if rollInDegrees > 20 {
                        return .right
                    }
                }
                return .none
            }
            
            DispatchQueue.main.async {
                if self.playerCount != limitedFaces.count {
//                    print("DEBUG: playerCount changed to \(limitedFaces.count)")
                    self.playerCount = limitedFaces.count
                }
                self.faceRollSide = faceRolls
                print("DEBUG: Detected face roll = \(faceRolls)°")
                if faceRolls.count == 2 {
                    if faceRolls[0] == faceRolls[1], self.lastRollSide != faceRolls[0] {
                        self.lastRollSide = faceRolls[0]
                        print("DEBUG: lastRollSide updated to \(self.lastRollSide)")
                    }
                }
            }
            
            let landmarksRequest = VNDetectFaceLandmarksRequest { request, error in
                guard let landmarksResults = request.results as? [VNFaceObservation] else { return }
                
                let sortedLandmarks = landmarksResults.sorted { $0.boundingBox.origin.x > $1.boundingBox.origin.x }
                let limitedLandmarks = sortedLandmarks.prefix(2)
                
                for (index, face) in limitedLandmarks.enumerated() {
                    guard let nose = face.landmarks?.nose else { continue }
                    let noseY = nose.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(nose.pointCount)
                    
                    if self.baselineNoseY[index] == nil {
                        self.baselineNoseY[index] = noseY
                    }
                    
                    guard let baseline = self.baselineNoseY[index] else { continue }
                    let deltaY = noseY - baseline
                    
                    switch self.nodState[index] {
                    case .idle:
                        if deltaY < -0.04 {
                            self.nodState[index] = .noddingDown
                        }
                        
                    case .noddingDown:
                        if deltaY > -0.015 {
                            self.nodState[index] = .noddingUp
                        }
                        
                    case .noddingUp:
                        self.hasNodded[index] = true
                        self.nodState[index] = .idle
                        self.baselineNoseY[index] = nil
                        
                    @unknown default:
                        break
                    }
                    
//                    DispatchQueue.main.async {
//                        self.playerOneNodded = self.hasNodded[0] ?? false
//                        self.playerTwoNodded = self.hasNodded[1] ?? false
//                    }
                }
                DispatchQueue.main.async {
                    self.playerOneNodded = self.hasNodded[0] ?? false
                    self.playerTwoNodded = self.hasNodded[1] ?? false
                }
            }
            
            let landmarksHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .down, options: [:])
            try? landmarksHandler.perform([landmarksRequest])
            
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .down, options: [:])
        do {
            try requestHandler.perform([faceRectanglesRequest])
        } catch {
            print("DEBUG: Face rectangles request failed - \(error.localizedDescription)")
        }
    }
}
