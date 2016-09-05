//
//  ViewController.swift
//  jesus
//
//  Created by Andreas Okholm on 05/09/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation
import AudioKit


class ViewController: UIViewController {

    @IBOutlet weak var renderView: RenderView!
    
    private let size = Size(width: 480, height: 640)

    private let rawOut = RawDataOutput()
    
    let mixer = AKMixer()
    var ocilators: [AKOscillator] = []
    var panners: [AK3DPanner] = []
    let N = 2
    let fMax: Double = 1000
    let fMin: Double = 500
    let thetaMax = M_PI
    let distance = 10
    var theta: Double = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // setup audio system
        ocilators = (0..<N).map { i in
            let o = AKOscillator()
            o.frequency = fMin + Double(i) * (fMax-fMin)/(N-1)
            o.start()
            return o
        }
        
        panners = (0..<N).map { i in
            let thetaIncrement = thetaMax*2/(N-1)
            let panner = AK3DPanner(ocilators[i],
                x: sin(-thetaMax + Double(i) * thetaIncrement)*distance,
                y: cos(-thetaMax + Double(i) * thetaIncrement)*distance,
                z: 0 )
            mixer.connect(panner)
            return panner
        }
        ocilators[1].amplitude=0
        
        AudioKit.output = mixer
        AudioKit.start()
        
        
        
        renderView.orientation = .LandscapeRight
        do {
            let camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera --> renderView
            camera --> rawOut
            camera.startCapture()
            
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
        
        
        
        rawOut.dataAvailableCallback = {
            buffer in
            
            let pixelLocations = (0..<self.N).map { i in
                return Int(i * self.size.height / Double(self.N - 1) + self.size.width/2)
            }
            
            let amplitudes = pixelLocations.map { pixelLocation in
                let r = buffer[pixelLocation]
                let g = buffer[pixelLocation + 1]
                let b = buffer[pixelLocation + 2]
                return Double(r + g + b) / Double(3*255)
            }
            
            

            dispatch_async(dispatch_get_main_queue(),{
                amplitudes.enumerate().map { (i, amplitude) in
                    self.ocilators[i].amplitude = amplitude
                }
            })
            
        }
        

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

