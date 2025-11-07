import React, { useRef, useEffect, useState } from 'react';
import './App.css';

// Your Adsterra Smartlink is perfectly placed.
const AD_URL = 'https://www.effectivegatecpm.com/euwk6tje?key=aeab73654d8b3c188f6d4ed2b26fdfda';

// The CINE-V3 Filter Recipe, translated to CSS filters. This is the smartest way for web performance.
const CINE_V3_FILTER = [
  `brightness(${1 + 2 / 100})`,      // Brightness: +2
  `contrast(${1 + 3 / 100})`,       // Contrast: +3
  `saturate(${1 + 12 / 100})`,      // Saturation: +12
  // Note: Brilliance, Sharpen, Clarity, etc., are approximated with contrast and sharpen-like effects.
  // We are using CSS filters which are GPU accelerated.
].join(' ');


function App() {
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const [isCameraOn, setCameraOn] = useState(false);

  // Function to start the camera
  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          width: { ideal: 4096 }, // Aim for 4K
          height: { ideal: 2160 },
          facingMode: 'environment' // Rear camera
        },
        audio: false,
      });
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        setCameraOn(true);
      }
    } catch (err) {
      console.error("Error accessing camera:", err);
      alert("Could not access the camera. Please grant permission and refresh.");
    }
  };

  // Main function to capture, show ad, and download
  const handleCaptureAndDownload = () => {
    if (!isCameraOn || !canvasRef.current || !videoRef.current) return;

    // Step 1: Show the Ad in a new tab. Clean and simple.
    window.open(AD_URL, '_blank');

    // Step 2: Draw the final, high-quality filtered image on the canvas
    const canvas = canvasRef.current;
    const video = videoRef.current;
    const context = canvas.getContext('2d');

    // Set canvas dimensions to high resolution
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    
    context.filter = CINE_V3_FILTER;
    context.drawImage(video, 0, 0, canvas.width, canvas.height);

    // Step 3: Trigger the download
    const link = document.createElement('a');
    link.download = 'v3-cap-image.png';
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  // Effect to start the camera on component mount
  useEffect(() => {
    startCamera();

    // Cleanup function to stop the camera when component unmounts
    return () => {
      if (videoRef.current && videoRef.current.srcObject) {
        videoRef.current.srcObject.getTracks().forEach(track => track.stop());
      }
    };
  }, []);
  
  // Effect for real-time preview on canvas
  useEffect(() => {
    let animationFrameId;

    const render = () => {
      if (isCameraOn && videoRef.current && canvasRef.current) {
        const canvas = canvasRef.current;
        const video = videoRef.current;
        const context = canvas.getContext('2d');

        // Match canvas aspect ratio to video aspect ratio
        canvas.width = video.clientWidth;
        canvas.height = video.clientHeight;

        context.filter = CINE_V3_FILTER;
        context.drawImage(video, 0, 0, canvas.width, canvas.height);
      }
      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => cancelAnimationFrame(animationFrameId);
  }, [isCameraOn]);


  return (
    <div className="app-container">
      {/* This video element is hidden. It's just a data source for our canvas. */}
      <video ref={videoRef} autoPlay playsInline style={{ display: 'none' }} />

      {/* This canvas is what the user sees. It shows the real-time filtered video. */}
      <canvas ref={canvasRef} className="camera-view" />

      {!isCameraOn && (
        <div className="loading-overlay">
          <p>Starting Camera...</p>
        </div>
      )}

      {isCameraOn && (
        <div className="ui-overlay">
          <button className="shutter-button" onClick={handleCaptureAndDownload}>
            <div className="shutter-icon">SAVE</div>
          </button>
        </div>
      )}
    </div>
  );
}

export default App;
