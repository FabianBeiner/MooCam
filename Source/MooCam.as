/**
 * MooCam - JavaScript meets Webcam.
 *
 * This is the ActionScript 3.0 part of MooCam.
 * You basically don't need to change anything here, except (maybe) the JPG
 * quality of the taken pictures. See variable below.
 *
 * If you change anything here, you need to recompile MooCam.fla.
 *
 *
 * @author       Fabian Beiner <mail@fabian-beiner.de>
 * @thanks       Marvin Blase <marvin@beautifycode.com>
 * @license      The MIT License (MIT)
 * @link         http://fabian-beiner.de
 * @version      1.0 Alpha
 */

package {
    import com.adobe.images.JPGEncoder; // This is part of as3corelib (BSD License).
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.events.StatusEvent;
    import flash.external.ExternalInterface;
    import flash.external.ExternalInterface;
    import flash.filters.ColorMatrixFilter;
    import flash.filters.ConvolutionFilter;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.system.Security;
    import flash.utils.ByteArray;

    public class MooCam extends MovieClip {
        private var imgBA:ByteArray;
        private var imgBitmapData:BitmapData;
        private var imgBitmap:Bitmap;
        private var jpgEncoder:JPGEncoder;
        private var jpgQuality:Number = 90; // Change the JPG quality if needed.
        private var videoStream:Video = null;
        private var webcamStream:Camera = null;

        public function MooCam() {
            Security.allowDomain("*");
            // Initialize the webcam.
            initializeWebcam(stage.stageWidth, stage.stageHeight);

            // Provide ActionScript functions to JavaScript.
            ExternalInterface.addCallback("deletePicture", deletePicture);
            ExternalInterface.addCallback("savePicture", savePicture);
            ExternalInterface.addCallback("takePicture", takePicture);
        }

        public function initializeWebcam(camWidth:int, camHeight:int):void {
            for (var i:int = 0; i < Camera.names.length; i++) {
                var cameraName:String = Camera.names[i];
                switch (cameraName) {
                    // Prefer the Apple iSight camera over everything else on a Mac.
                    case "USB Video Class Video":
                        webcamStream = Camera.getCamera(cameraName);
                        break;
                    // Otherwise select just any available camera. :)
                    default:
                        webcamStream = Camera.getCamera();
                }
            }

            if (webcamStream != null) {
                imgBitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, true, 0x000000);
                imgBitmap = new Bitmap(imgBitmapData);

                webcamStream.setQuality(0, 100);
                webcamStream.setMotionLevel(100);
                webcamStream.setMode(camWidth, camHeight, stage.frameRate, false);

                videoStream = new Video(camWidth, camHeight);
                videoStream.attachCamera(webcamStream);

                addChild(videoStream);
                addChild(imgBitmap);

                webcamStream.addEventListener(StatusEvent.STATUS, camStatusHandler);
            }
            else {
                ExternalInterface.call("MooCam.MsgFromFlash", "No camera detected");
            }
        }

        public function camStatusHandler(event:StatusEvent):void {
            switch (event.code) {
                case 'Camera.Muted':
                    ExternalInterface.call("MooCam.camMuted");
                    break;
                case 'Camera.Unmuted':
                    ExternalInterface.call("MooCam.camUnmuted");
                    break;
            }
        }

        private function takePicture(filter:String = ""):Boolean {
            if (webcamStream != null) {
                switch (filter) {
                    case "edges":
                        var edgesFilter:ConvolutionFilter = new ConvolutionFilter(3, 3, [0, -1, 0, -1, 4, -1, 0, -1, 0], 1);
                        imgBitmap.filters = [edgesFilter];
                        break;
                    case "emboss":
                    case "embossing":
                        var embossFilter:ConvolutionFilter = new ConvolutionFilter(3, 3, [-2, -1, 0 , -1, 1, 1 , 0, 1, 2], 1);
                        imgBitmap.filters = [embossFilter];
                        break;
                    case "invert":
                    case "inverted":
                        var invertFilter:ColorMatrixFilter = new ColorMatrixFilter([-1, 0, 0, 0, 255, 0 ,-1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]);
                        imgBitmap.filters = [invertFilter];
                        break;
                    case "monochrome":
                    case "blackwhite":
                    case "bw":
                        var monochromeFilter:ColorMatrixFilter = new ColorMatrixFilter([0.3, 0.6, 0.1, 0, 0, 0.3, 0.6, 0.1, 0, 0, 0.3, 0.6, 0.1, 0, 0, 0, 0, 0, 1, 0]);
                        imgBitmap.filters = [monochromeFilter];
                        break;
                    case "sepia":
                        var sepiaFilter:ColorMatrixFilter = new ColorMatrixFilter([0.3930000066757202, 0.7689999938011169, 0.1889999955892563, 0, 0, 0.3490000069141388, 0.6859999895095825, 0.1679999977350235, 0, 0, 0.2720000147819519, 0.5339999794960022, 0.1309999972581863, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1]);
                        imgBitmap.filters = [sepiaFilter];
                        break;
                }

                imgBitmapData.draw(videoStream);
                return true;
            }
            return false;
        }

        private function deletePicture():void {
            imgBitmap.filters = [];
            imgBitmapData.fillRect(imgBitmapData.rect, 0);
        }

        private function savePicture(name:String = ""):Boolean {
            var filteredBD:BitmapData = new BitmapData(imgBitmap.width, imgBitmap.height);
            filteredBD.draw(imgBitmap);

            if (filteredBD != null) {
                var jpgEncoder:JPGEncoder = new JPGEncoder(jpgQuality);
                var jpgStream:ByteArray = jpgEncoder.encode(filteredBD);
                var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
                var jpgURLRequest:URLRequest = new URLRequest("save.php");
                jpgURLRequest.requestHeaders.push(header);
                jpgURLRequest.method = URLRequestMethod.POST;
                jpgURLRequest.data = jpgStream;
                navigateToURL(jpgURLRequest, "_blank");
                return true;
            }
            return false;
        }
    }
}
