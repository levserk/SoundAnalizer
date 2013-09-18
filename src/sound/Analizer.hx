package sound;

import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import flash.media.Sound;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.utils.Function;
import flash.Memory;
import flash.Vector;


/**
 * ...
 * @author levserk
 */

class Analizer extends Sprite
{

	public var sound:Sound;
	public var fft:Fft;
	public var peakA:PeakAnalizer;
	
	public static var step:Int = 32;
	public var perLoad:Float=1;
	public var progress:Float;
		
	public var initflag:Bool = false; //is sound analized or not
	private var flaginita:Bool = true;//result initializing
	private var i:Int = 0;
	
	public var timest:Int; public var timeend:Int;
	public var tspeed:Int;	public var tspeedmin:Int = 99999; public var tspeedmax = 0; 
	public var tspeedmean:Float = 0;
	public var tfreqmean:Float = 0;
	public var tpeaksmean:Float = 0;
	public var stoken:String = ""; 
	
	private var soundData:ByteArray;
	private var soundDataLength:Int;
	private var max:Float;
	private var min:Float;
	private var leftMin:Float;
	private var leftMax:Float;
	private var rightMin:Float;
	private var rightMax:Float;
	private var leftc:Float;
	private var rigthc:Float;
	private var val:Float;
	private var step44:Int;
	private var mult:Float;
	private var ipos:Int = 0;
	
	public var fsinf:SpectrInfo;
	private var ssinf:SpectrInfo;
	private var sinf:SpectrInfo;
	public var fpeak:Peak;
	private var peak:Peak;
	public var fival:Interval;
	private var interval:Interval;
	private var iInd:UInt = 0;
	private var pInd:UInt = 0;
	
	public var targValues:Vector<Float>;
	
	inline static public var eCompleate:String = "SOUND_ANALIZE_COMPLEATE";
	inline static public var eError:String = "SOUND_ANALIZE_ERROR";
	private var onProgress:Function=null;
	private var ferror = false;
	
	
	public function new() 
	{
		soundData = new ByteArray();
		soundData.endian = Endian.LITTLE_ENDIAN;
		step44 = Std.int(44.1 * step);
		soundDataLength = soundData.length = step44 * 8;
		Memory.select(soundData);
		super();
	}
	
	private function destroy(e : Event) : Void {
		removeEventListener(Event.ENTER_FRAME, enterf);	
	}
	
	public function init(s:Sound, minPeakAmpl:Float=0.011, fftSpectrLength:Int=512, maxTimeInitFrame:Int=100):Void {
		if (!initflag) {
			maxTimeInit = maxTimeInitFrame;
			ferror = false;
			sound = s;
			fft = new Fft(fftSpectrLength); 
			peakA = new PeakAnalizer(minPeakAmpl);
			interval = null; peak = null; ssinf = null;
			fival = null; fpeak = null; fsinf = null; ssinf = null; sinf = null;
			stoken = "";
			mult = 1 / step44;
			ipos = 0;
		} else trace("old init not compleate");
	}
	
	inline public function start(per:Float=0, _onProgress:Function=null):Void {
		if (!initflag) {
			addEventListener(Event.ENTER_FRAME, enterf);
			onProgress = _onProgress;
			
			ipos = 0;
			stoken = "";
			perLoad = per;
			initflag = true;
			flaginita = true;
			fsinf = null; 
			ssinf = null;
			
			timest = Lib.getTimer();
			trace ("start", timest);
		} else trace("old init not compleate");
	}
	
	public function cancel():Void {
		interval = null;
		peak = null; 
		ssinf = null;
		fival = null; 
		fpeak = null; 
		fsinf = null; 
		sinf = null;
		stoken = ""; 
		peakA = new PeakAnalizer(0);
		initflag = false; flaginita = false;
		removeEventListener(Event.ENTER_FRAME, enterf);	
	}
	
	inline private function stop():Void {
	try{	
		peakA.analizePeaks();
		stoken = peakA.getSoundToken();
		fpeak = peakA.fpeak;
		fival = peakA.fival;
		calcTSpeed();
		
		ssinf = null; sinf = null; interval = null; peak = null; 
		initflag = false; 
		
		timeend = Lib.getTimer();
		trace("end", timeend - timest, Int(sound.length), (timeend - timest) / sound.length);
		
		removeEventListener(Event.ENTER_FRAME, enterf);	
		
		dispatchEvent(new Event(eCompleate));
		}  catch (msg : String) { trace(msg); error();  }
	}
	
	inline private function error():Void {
		ferror = true;
		initflag = false; 
		removeEventListener(Event.ENTER_FRAME, enterf);	
		ssinf = null; sinf = null; interval = null; peak = null; 
		fsinf = null; fpeak = null; fival = null;
		dispatchEvent(new Event(eError));
	}
	
	inline public function analizeSoundSpectr(position:Int):Vector<Float> {
		targValues = fft.calcSpectrum(position, sound);
		return targValues;
	}
	
	/*
	private var spectrLength:Int = -1; 
	private var value:Float;
	private var meanVal:Float;
	inline public function analize(spectrData:ByteArray, ipos:Int, fnormalize:Bool = true):Void {
		try{
		if (spectrData!=null){
			spectrLength = spectrData.length >> 2;
			if (spectrLength > 0) {
				targValues = new Vector<Float>();
				spectrData.position = 0; meanVal = 0;
				while (spectrData.bytesAvailable>0){
					value = fnormalize?normalize(spectrData.readFloat()):spectrData.readFloat();
					meanVal += value; 
					targValues.push(value);
				}
				meanVal /= spectrLength; 
				peakA.analize(meanVal, ipos);
				sinf = new SpectrInfo(ipos, targValues, meanVal, ssinf);
				if (fsinf == null) fsinf = sinf;
				if (ssinf != null) ssinf.next = sinf;
				ssinf = sinf;
			}
		}
		}  catch (msg : String) { trace(msg); error();  }
	}
	*/
	
	private var t1:Int;
	public var maxTimeInit:Int=100;
	private function enterf(e:Event):Void {
		if (initflag) {
			t1 = Lib.getTimer();
			while(Lib.getTimer()-t1<maxTimeInit&&flaginita){
				flaginita = initSound();
			}
			if (onProgress != null) onProgress(progress);
			if (!flaginita && !ferror) stop();
		}
	}
	
	
	private var tsif:Int = 0;
	private var tsil:Int = 0;
	private var tpef:Int = 0;
	private var tpel:Int = 0;
	private function initSound():Bool {
		try{
		if (sound.length - ipos >= step * (perLoad < 1?10:3)) { 
			soundData.position = 0;
			sound.extract(soundData, step44, Std.int(ipos*44.1));
			soundData.position = 0;
			leftMin = 2; leftMax = -2;
			rightMin = 2; rightMax = -2;
			leftc = 0; rigthc = 0; val = 0; 
			min = 0; max = 0; i = 0;
			while (i < soundDataLength) {
				leftc = soundData.readFloat();
				//leftc = Memory.getFloat(i); 
				i += 4;
				rigthc = soundData.readFloat();
				//rigthc = Memory.getFloat(i); 
				i += 4;
				if (leftc < leftMin) leftMin = leftc;
				if (leftc > leftMax) leftMax = leftc;
				if (rigthc < rightMin) rightMin = rigthc;
				if (rigthc > rightMax) rightMax = rigthc;
				max += leftc * leftc;
				min += rigthc * rigthc;
			}
			leftc = Math.sqrt(max * mult);
			rigthc = Math.sqrt(min * mult);
			val = (leftc + rigthc) * .5;	
			peakA.analize(val, ipos);
			sinf = new SpectrInfo(ipos, null, val, ssinf, leftc, rigthc, rightMax, rightMin, leftMax, leftMin);
			if (fsinf == null){ fsinf = sinf; tsif = sinf.time; }
			if (ssinf != null) ssinf.next = sinf;
			ssinf = sinf;
			progress = (ipos / (sound.length / perLoad));
			ipos += step;
			tsil = sinf.time;
		}
		if (perLoad == 1 && sound.length - ipos - step*3 < 0) return false;
		else return true;
		}  catch (msg : String) { trace(msg); error(); }
		return false;
	}	
	
	inline private function calcTSpeed():Void {
		try{
		tspeed = 0; tspeedmean = 0; tfreqmean = 0; tpeaksmean = 0; i = 0;
		var intr:Interval = fival;
		while (intr != null) {
			i++;
			tspeed = Std.int(intr.getSpeed());
			if (tspeedmax<tspeed) tspeedmax=tspeed;
			if (tspeedmin > tspeed) tspeedmin = tspeed;
			tspeedmean += intr.getSpeed() * intr.length() / sound.length;
			tfreqmean += intr.meanT * intr.length() / sound.length * 0.001;
			tpeaksmean += intr.n *  intr.length() / sound.length;
			intr = intr.next;
		}
		tspeedmean 	/= i;
		tfreqmean 	/= i;	
		tpeaksmean	/= i;
		}  catch (msg : String) { trace(msg); error(); }
	}
	

	inline public function getInterval(t:Int,s:Interval=null):Interval{
		if (t < 0) interval = null; 
		else if (s != null) interval = s;
		if (interval != null) interval = interval.find(t);
		else interval = fival.find(t);
		return interval;
	}

	inline public function getPeak(t:Int,s:Peak=null):Peak {
		if (t <= fpeak.time) peak = null;
		else if (s != null) peak = s;
		if (peak != null) peak = peak.find(t);
		else peak = fpeak.find(t);
		return peak;
	}
	inline public function getSpectr(t:Int,s:SpectrInfo=null):SpectrInfo {
		if (t < tsif || t > tsil) { ssinf = null; trace(t, tsif, tsil); }
		else if (s != null) ssinf = s.find(t);
			 else if (ssinf != null) ssinf = ssinf.find(t);
				  else ssinf = fsinf.find(t);
		return ssinf;
	}
	
	public function test():Void {
		fsinf.find(step * 4);
	}
	
//-----------------------------------------------------------------------------	

	inline public function log2(value:Float):Float {
		return (Math.log(value) / Math.log(2));
	}
	
	private var k:Float = 1/5;
	public function setNormlizeK(value):Void { 
		//k = Std.int(log2(value)); 
		k = 1 / value;
	}
	inline public function normalize(value:Float):Float {
		// Hyperbolic tangent tanh:
		return (Math.exp(value * k) - 1) / (Math.exp(value * k) + 1);
	}
	
}