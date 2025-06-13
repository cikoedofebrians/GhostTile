//
//  BlinkManager.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 13/06/25.
//

import Vision
import AVFoundation
import UIKit

class BlinkManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session = AVCaptureSession()
    var onBlinkDetected: (() -> Void)?

    private var previousLeftOpen = true
    private var previousRightOpen = true

    override init() {
        super.init()
        configureCamera()
    }

    private func configureCamera() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No front camera.")
            return
        }

        session.sessionPreset = .medium

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            session.addInput(input)
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        session.addOutput(output)
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation], let face = observations.first else { return }

            guard let landmarks = face.landmarks,
                  let leftEye = landmarks.leftEye,
                  let rightEye = landmarks.rightEye else { return }

            let leftClosed = self?.isEyeClosed(leftEye) ?? false
            let rightClosed = self?.isEyeClosed(rightEye) ?? false

            if leftClosed && rightClosed {
                if self?.previousLeftOpen == true && self?.previousRightOpen == true {
                    DispatchQueue.main.async {
                        self?.onBlinkDetected?()
                    }
                }
                self?.previousLeftOpen = false
                self?.previousRightOpen = false
            } else {
                self?.previousLeftOpen = true
                self?.previousRightOpen = true
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        try? handler.perform([request])
    }

    private func isEyeClosed(_ eye: VNFaceLandmarkRegion2D) -> Bool {
        guard eye.pointCount >= 6 else { return false }
        
        let points = eye.normalizedPoints
        let vertical = distance(points[1], points[5])
        let horizontal = distance(points[0], points[3])

        let ratio = vertical / horizontal
        return ratio < 0.2
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx*dx + dy*dy)
    }
}
