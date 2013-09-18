package ;
import flash.display.Graphics;
import flash.events.KeyboardEvent;
import flash.Lib;
import flash.display.Sprite;
import flash.events.Event;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.text.TextField;
import flash.Vector;
import sound.Analizer;
import sound.Interval;
import sound.Peak;
import sound.SpectrInfo;

/**
 * ...
 * @author levserk
 */
class Demo extends Sprite {
	
	
	

	private var line:Sprite;
	private var sref:FileReference;
	private var s:Sound;
	private var ch:SoundChannel;
	private var a:Analizer;
	private var w:Int;
	private var h:Int;
	private var VOLUME:Float = 0.5;
	
	private var oldPos:Float = 0;
	private var pos:Int = 0;
	private var xx:Int = 0;
	private var moved:Float = 0;
	private var si:SpectrInfo;
	private var peak:Peak;
	private var int:Interval;
	private var speed:Int = 0;
	private var i:Int = 0;
	
	private var tf:TextField;
	
	private var spectr:Sprite;
	private var vspectr:Vector<Float>;
	private var val:Float;
	private var SPECTR_HEIGHT:Int = 200;
	private var streth:Float = 0.15;
	
	public function new() {	
		w = Lib.current.stage.stageWidth;
		h = Lib.current.stage.stageHeight;
		
		line = new Sprite();
		line.graphics.lineStyle(2, 0x6A006A);
		line.graphics.moveTo(0, 450); line.graphics.lineTo(0, 800);
		addChild(line);

		tf = new TextField();
		tf.width = 250;
		addChild(tf);
		
		var mestf:TextField = new TextField();
		mestf.text = "press O to open mp3 file";
		mestf.y = 30; mestf.width = 250;
		addChild(mestf);
		
		spectr = new Sprite();
		addChild(spectr);
		spectr.x = w / 2 - 256;
		spectr.y = 100;

		addEventListener(Event.ADDED_TO_STAGE, init);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		super();
	}
	
	private function init(e:Event = null):Void {
		a = new Analizer();
		a.addEventListener(Analizer.eCompleate, onAnalizeCompleted);
		vspectr = new Vector(512, true);
		
		sref = new FileReference();
		sref.addEventListener(Event.SELECT, onFileSelected);
		sref.addEventListener(Event.COMPLETE, onFileOpened);
		
		var data = haxe.Resource.getBytes("music");
		if (data == null)	sref.browse([new FileFilter("Sound", "*.mp3")]);
		else {
			s = new Sound();
			s.loadCompressedDataFromByteArray(data.getData(),data.length);
			a.init(s, 0.015, 512, 250);
			a.start(1, onProgress);
		}
		
	}
	
	private function onFileSelected(e:Event):Void {
		sref.load();
	}
	
	private function onFileOpened(evt:Event):Void {
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		if (ch != null) ch.stop();
		a.cancel();
		s = new Sound();
		s.loadCompressedDataFromByteArray(sref.data,sref.data.length);
		a.init(s, 0.015, 512, 250);
		a.start(1, onProgress);
		
		graphics.clear(); 
		pos = 0; xx = 0; line.x = 0; oldPos = 0; moved = 0;
		si = null; peak = null; int = null;
	}
	
	private function onProgress(progress:Float):Void {
		tf.text = "analize: " + Std.int(progress * 100) +"%";
	}
	
	private function onAnalizeCompleted(e:Event) {
		Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		ch = s.play(0, 0, new SoundTransform(VOLUME));
	}
	
	private function onKeyPressed(e:KeyboardEvent) {
		if (e.keyCode == 79) { // key O
			sref.browse([new FileFilter("Sound", "*.mp3")]);
		}
	}
	
	private function onEnterFrame(e:Event):Void {
		i = 0;
		var intr:Interval = null;
		if (pos < s.length && xx < w) {
			while(++i<50 && pos < s.length && xx < w){
				si = a.getSpectr(pos, si);
				peak = a.getPeak(pos, peak);
				intr = a.getInterval(pos, int);
				
				pos += Analizer.step;
				xx+=2;
				if (intr != int && intr != null) {
					drawGraph(xx, graphics, (peak != null), true);
					drawWave(xx, graphics);
					int = intr;
				}
				drawGraph(xx, graphics, (peak != null));
				drawWave(xx, graphics);
			}
		}
		
		if (line.x>=w) {
			moved += w;
			xx = 0;
			graphics.clear();
			graphics.lineStyle(1, 0x0000FF);
		}
		
		drawSpectr();
		
		intr = a.getInterval(Std.int(ch.position / Analizer.step) * Analizer.step, intr);
		if (intr != null) speed = Std.int(intr.getSpeed());
		line.x = ch.position / Analizer.step * 2 - moved;
		tf.text = "position: " + Std.int(ch.position) + " sound speed: " + speed; 
	}
	
	// sound Graph	
	private inline function drawGraph(x, g:Graphics,fpeak:Bool=false, fintr:Bool=false, topY:Int=600, lHeight:Int=200):Void {
		if (si != null) {
			g.lineStyle(2, 0x1C21E1);
			g.moveTo(x - 2, topY - oldPos * lHeight);
			g.lineTo(x, topY - si.mean * lHeight); 
			oldPos = si.mean;
		}
		if (fpeak) {
			g.lineStyle(2, 0xFF8000);
			g.drawCircle(x,  topY - oldPos * lHeight, 2);
			g.lineStyle(2, 0x0000FF);
		}
		if (fintr) {
			g.lineStyle(2, 0xFF8000);
			g.moveTo(x, topY);
			g.lineTo(x, topY - 100);
			g.lineStyle(2, 0x0000FF);
		}
	}
	
	// sound Wave
	private inline function drawWave(x, g:Graphics, topY:Int = 800, WHeigt:Int = 100) :Void {
		if (si != null) {
			g.lineStyle(2, 0x53D559);
			g.moveTo(x, topY - WHeigt + WHeigt * si.rightMax);
			g.lineTo(x, topY - WHeigt - WHeigt * si.leftMax);
			g.lineStyle(2, 0x228827);
			g.moveTo(x, topY - WHeigt + WHeigt * si.rightMean);
			g.lineTo(x, topY - WHeigt - WHeigt * si.leftMean);
		}
	}
	
	// sound Spectrum
	private inline function drawSpectr():Void {
		a.analizeSoundSpectr(Std.int(ch.position));
		spectr.graphics.clear();
		spectr.graphics.lineStyle(1, 0);
		for (i in 0...Std.int(vspectr.length) - 1) {
			val = vspectr[i] + (a.normalize(a.fft.spectr[i])-vspectr[i]) * streth;
			spectr.graphics.moveTo(i, SPECTR_HEIGHT);
			spectr.graphics.lineTo(i, SPECTR_HEIGHT - SPECTR_HEIGHT * val);
			vspectr[i] = val;
		}
	}
	
	
}