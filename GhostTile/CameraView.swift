//
//  CameraView.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 05/06/25.
//

import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewRepresentable {
    typealias UIViewType = UIView
    @Binding var tiltCounts: [Double]
    @Binding var rollSide: RollSide
    @Binding var ballIndex: Int
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        context.coordinator.previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(context.coordinator.previewLayer)
        
        context.coordinator.startSession()
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(tiltCounts: $tiltCounts, rollSide: $rollSide, ballIndex: $ballIndex)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Binding var tiltCounts: [Double]
    @Binding var rollSide: RollSide
    @Binding var ballIndex: Int
    let session = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "videoQueue")
    
    init(tiltCounts: Binding<[Double]>, rollSide: Binding<RollSide>, ballIndex: Binding<Int>) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        self._tiltCounts = tiltCounts
        self._rollSide = rollSide
        self._ballIndex = ballIndex
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
                let faceRolls = results.map { face in
                    if let roll = face.roll {
                        // Convert radians to degrees
                        let rollInDegrees = roll.doubleValue * (180.0 / .pi)
                        print("Face Roll: \(rollInDegrees) degrees")
                        return rollInDegrees
                    }
                    
                    return 0.0
                }
                withAnimation {
                    self.tiltCounts = faceRolls
                }
                
                
                if faceRolls.count == 2 {
                    if faceRolls[0] < 60 && faceRolls[1] < 60 && self.rollSide == .straight {
                        print("Left Roll Detected")
                        self.rollSide = .left
                        if self.ballIndex > 0 {
                            withAnimation {
                                self.ballIndex -= 1
                            }
                        }
                    } else if faceRolls[0] > 120 && faceRolls[1] > 120 && self.rollSide == .straight {
                        print("Right Roll Detected")
                        self.rollSide = .right
                        if self.ballIndex < 3 {
                            withAnimation {
                                self.ballIndex += 1
                            }
                            
                        }
                    } else if faceRolls[0] > 60 && faceRolls[0] < 120 && faceRolls[1] > 60 && faceRolls[1] < 120 && self.rollSide != .straight {
                        print("Straight Roll Detected")
                        self.rollSide = .straight
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        
        try? handler.perform([request])
        
        
    }
    
}
