package {
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.display.GradientType;
    import flash.display.SpreadMethod;
    import flash.display.Sprite;
    import flash.filters.BitmapFilter;
    import flash.filters.DisplacementMapFilter;
    import flash.filters.DisplacementMapFilterMode;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.text.TextField;
    
    public class DisplacementMapFilterExample extends Sprite {
        private var bgColor:uint     = 0xFFCC00;
        private var size:uint        = 200;
        private var offset:uint      = 90;
        private var labelText:String = "Watch the text bend with the displacement map";

        public function DisplacementMapFilterExample() {
            draw();
            createLabel();
            createFilter();
        }

        private function createFilter():void {
            var filter:BitmapFilter = getBitmapFilter();
            filters = new Array(filter);
        }

        private function getBitmapFilter():BitmapFilter {
            var mapBitmap:BitmapData = createBitmapData();
            var mapPoint:Point       = new Point(0, 0);
            var channels:uint        = BitmapDataChannel.RED;
            var componentX:uint      = channels;
            var componentY:uint      = channels;
            var scaleX:Number        = 0.5;
            var scaleY:Number        = -30;
            var mode:String          = DisplacementMapFilterMode.CLAMP;
            var color:uint           = 0;
            var alpha:Number         = 0;
            return new DisplacementMapFilter(mapBitmap,
                                             mapPoint,
                                             componentX,
                                             componentY,
                                             scaleX,
                                             scaleY,
                                             mode,
                                             color,
                                             alpha);
        }

        private function draw():void {
            var matrix:Matrix = new Matrix();
            matrix.createGradientBox(size, size);
            graphics.beginGradientFill(GradientType.RADIAL,
                                       [0xFF0000, 0x0000FF],
                                       [100, 100],
                                       [55, 200],
                                       matrix,
                                       SpreadMethod.PAD);
            graphics.drawRect(0, 0, size, size);
        }

        private function createBitmapData():BitmapData {
            var bitmapData:BitmapData = new BitmapData(size, size, true, bgColor);
            bitmapData.draw(this, new Matrix());
            var bitmap:Bitmap = new Bitmap(bitmapData);
            bitmap.x = size;
            addChild(bitmap);
            return bitmapData;
        }

        private function createLabel():void {
            var tf:TextField = new TextField();
            tf.text = labelText;
            tf.y = offset;
            tf.width = size;
            addChild(tf);
        }
    }
}