import Vision
import AVFoundation
import UIKit

class BlinkDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var onLeftBlinkDetected: (() -> Void)?
    var onRightBlinkDetected: (() -> Void)?
    
    var session = AVCaptureSession()
    private var previousEyeState: [Bool] = [true, true] // [leftPersonOpen, rightPersonOpen]
    
    var totalBlinks = 0
    var onBlinkCountReached: (() -> Void)? // trigger setelah total blink tertentu

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
            guard let self = self,
                  let observations = request.results as? [VNFaceObservation],
                  observations.count >= 2 else { return } // pastikan dua wajah

            var blinkStates: [Bool] = []

            for face in observations.prefix(2) {
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

            if blinkStates[0] && !self.previousEyeState[0] {
                DispatchQueue.main.async {
                    self.totalBlinks += 1
                    print("Left blinked. Total: \(self.totalBlinks)")
                    self.onLeftBlinkDetected?()
                }
            }

            if blinkStates[1] && !self.previousEyeState[1] {
                DispatchQueue.main.async {
                    self.totalBlinks += 1
                    print("Right blinked. Total: \(self.totalBlinks)")
                    self.onRightBlinkDetected?()
                }
            }

            self.previousEyeState = blinkStates.map { !$0 }
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
        return ratio < 0.3
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx*dx + dy*dy)
    }
}

