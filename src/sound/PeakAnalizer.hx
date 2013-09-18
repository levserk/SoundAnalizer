package sound;
import flash.errors.Error;

/**
 * ...
 * @author levserk
 */

class PeakAnalizer 
{
	public var intervals:flash.Vector<Interval>;
	private var oldmin:Float = 2; private var oldmax:Float = 0; private var oldtime:Int = 0; private var oldval:Float = 0;
	private var oldoldval:Float = 0;  
	private var oldiv:Interval; private var ival:Interval; public var fival:Interval; private var lival:Interval;
	private var c:Float; private var d:Float; private var delt:Float;
	private var A:Float; private var H:Float; private var T:Int; private var meanA:Float = 0; private var meanH:Float = 0; private var meanT:Float = 0; 
	private var peak:Peak;	private var oldpeak:Peak = null; public var fpeak:Peak;
	private var step:Int = 0;
	private var peakAmpl:Float = 0.11;

	public function new(_peakAmpl:Float=0.011) { 
		intervals = new flash.Vector<Interval>();
		step = Analizer.step;
		meanH = 0; A = 0; H = 0; T = 0;
		if (_peakAmpl >0 && _peakAmpl<1) peakAmpl = _peakAmpl;
	}
	
	private var timeoldpeak:Int = 0;
	
	private var flag:Bool;
	inline public function analize(val:Float, time:Int):Void {
		if (val != val) val = 0;
		peak = null;
		if (val > oldval) {
			if (oldoldval > oldval /*&& oldval < val && oldmin>oldval*/) {//trench
				oldmin = oldval;
			}
		} else
		if (oldoldval < oldval && oldval > val) {//peak
			if (oldpeak != null) timeoldpeak = oldpeak.time;
			A = oldval - oldmin; H = oldval; T = oldtime-timeoldpeak;
			//trace(H, H * 1, 5);
			if (A > peakAmpl && T > 32) {
				peak = new Peak(oldtime, A, H, T, meanH, Std.int(T / step), oldpeak);	
				if (fpeak == null) fpeak = peak;
				if (oldpeak != null) oldpeak.next = peak;
				meanH = 0;
				oldmax = oldval;
				oldpeak = peak;
			}
		}
		oldoldval = oldval;
		oldval = val;
		oldtime = time;
		meanH += val;
	}
		
	inline public function analizePeaks():Void {
		var  c1:Float, c2:Float, c3:Float;
		oldiv = null;
		if (fpeak.next!=null){
			ival = new Interval(fpeak.time, fpeak.next.time, 1, fpeak.next.A, fpeak.next.meanH, fpeak.next.T);
			intervals.push(ival); fival = ival; lival = ival;
			oldiv = ival;
		}
		peak = fpeak.next.next;	
		while(peak!=null) {
			c1 = compIntPeak(oldiv,peak);
			if (peak.next!=null){
				c2 = compPeakPeak(peak, peak.next);
				c3 = compPeakPeak(peak, peak.prev);
				if ((peak.time-oldiv.t1<1000)||c1>0.60||(c1>c2&&c1>0.45)||(c3>c2&&c3>0.45)) oldiv.addPeak(peak);
				else {
					ival = new Interval(peak.prev.time, peak.time, 1, peak.A, peak.meanH, peak.T,oldiv);
					intervals.push(ival); oldiv.next = ival;
					oldiv = ival;
				}
			} else  if ((peak.time-oldiv.t1<1000)||c1>0.45) oldiv.addPeak(peak);
					else {
						ival = new Interval(peak.prev.time, peak.time, 1, peak.A, peak.meanH, peak.T,oldiv);
						intervals.push(ival); oldiv.next = ival;
					}
			peak = peak.next;
		}
		analizeintervals();
	}
	
	private function analizeintervals():Void {
		var flag:Bool = false;
		ival = fival.next;
		while (ival != null && ival.next != null) {
			var d = compIntInt(ival, ival.prev);
			var c = compIntInt(ival, ival.next);
			if (c > d) oldiv = ival.next; else { oldiv = ival.prev; c = d; }
			if (ival.length() < 1000 		
			||((ival.length() < 2000 || oldiv.length() < 2000 || ival.length() + oldiv.length()<4000) && c > 0.15) 
			||(ival.length() + oldiv.length()<7000 && c > 0.5)
			||c > 0.7)
			{
			//	trace(ival.length()+','+oldiv.length()+','+ival.meanT+','+oldiv.meanT+','+ival.meanA+','+oldiv.meanA+','+c+','+ "same");
				oldiv.addInterval(ival);
				ival.remove();
				if(!flag) flag = true;
			} 
			ival = ival.next;
		}
		if (flag) analizeintervals();
	}
	
	public var meanBPM:Float;
	public var meanAmp:Float;
	public var countIntervals:Int;
	public var timeSongStart:Int;
	public var timeSongEnd:Int;
	inline public function getSoundToken():String {
		var token:String = "";
		var va1:Int = 0; var va2:Int; var va3:Int = 0;
		countIntervals = 0;
		if (fival!=null){
			timeSongStart = fival.t1;
			meanBPM = meanAmp = countIntervals = 0;
			var ival:Interval = fival.next;
			while (ival != null) {
				meanBPM += ival.n / ival.length() * 6000;
				meanAmp += ival.meanA;
				timeSongEnd = ival.t2;
				countIntervals++;
				ival = ival.next;
			}
			meanAmp /=  countIntervals;
			meanBPM /=  countIntervals;
			va1 = countIntervals;
			va2 = Std.int(meanAmp*1000);
			va3 = Std.int(meanBPM);
			token = countIntervals+ "|" + va3 + "|" + va2 + "|" + Std.int((timeSongEnd - timeSongStart)/10);
		}
		// 90000|999|999|999
		// 900719|925|474|0992 
		// length|va3|va2|va1 = 10*song seconds| meanBPM | meanAmp |  countIntervals
		return token;
	}
		
	inline private function compIntPeak(iv:Interval,pe:Peak):Float{
		var c:Float=0;
		try {
			c = 1;
			c*=iv.meanT>pe.T?pe.T/iv.meanT:iv.meanT/pe.T;
			c*=iv.meanA>pe.A?pe.A/iv.meanA:iv.meanA/pe.A;
			c*=iv.meanH()>pe._meanH()?pe._meanH()/iv.meanH():iv.meanH()/pe._meanH();
		}
		catch (e:Error) { c = 0; }
		return c;
	}
	
	inline private function compPeakPeak(pe1:Peak,pe2:Peak):Float{
		var c:Float=0;
		try {
			c = 1;
			c*=pe1.T>pe2.T?pe2.T/pe1.T:pe1.T/pe2.T;
			c*=pe1.A>pe2.A?pe2.A/pe1.A:pe1.A/pe2.A;
			c*=pe1._meanH()>pe2._meanH()?pe2._meanH()/pe1._meanH():pe1._meanH()/pe2._meanH();
		}
		catch (e:Error) { c = 0; }
		return c;
	}
	
	inline private function compIntInt(iv1:Interval,iv2:Interval):Float{
		var c:Float=0;
		try{
			c*=iv1.meanT>iv2.meanT?iv2.meanT/iv1.meanT:iv1.meanT/iv2.meanT;
			c*=iv1.meanA>iv2.meanA?iv2.meanA/iv1.meanA:iv1.meanA/iv2.meanA;
			c*=iv1.meanH()>iv2.meanH()?iv2.meanH()/iv1.meanH():iv1.meanH()/iv2.meanH();
		}
		catch (e:Error) {  c = 0; }
		return c;
	}

}