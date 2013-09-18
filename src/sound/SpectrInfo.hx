package sound;

/**
 * ...
 * @author levserk
 */

class SpectrInfo 
{
	public var tvals:flash.Vector<Int>=null;
	inline static public var counter:Int = 1000;
	public var mean:Float;
	public var leftMean:Float;
	public var rightMean:Float;
	public var rightMax:Float;
	public var rightMin:Float;
	public var leftMax:Float;
	public var leftMin:Float;
	public var time:Int;
	public var next:SpectrInfo;
	public var prev:SpectrInfo;
	public var pos:Float = -1;
	public var i:Int;
	public var pos2:Float = -1;

	public function new(_time:Int, v:flash.Vector<Float>, m:Float, _prev:SpectrInfo = null, _leftMean:Float = 0,
						_rightMean:Float=0, _rightMax:Float=0,_rightMin:Float=0, _leftMax:Float=0, _leftMin:Float=0){
		prev = _prev;
		time = _time;	mean = m; if (mean != mean) mean = 0;
		rightMean = _rightMean; leftMean = _leftMean;
		rightMax = _rightMax; rightMin = _rightMin;
		leftMax = _leftMax; leftMin = _leftMin;
		if (v!=null && v.length>0){
			var oldval:Int = 0; var oldoldval:Int = 0; var val:Int = 0; var f:Int = -1; var l:Int = 0;
			
			tvals = new flash.Vector<Int>(v.length);
			var i:Int = 0;
			var sum:Float = 0; var delta:Int=0;
			while (i < v.length) { 
				val = Std.int(v[i] * counter);
				if (i < v.length / 2) sum += v[i];
				tvals[i] = val; 
				if (i>1&&prev!=null&&prev.tvals[i-1]<oldval &&oldoldval<oldval&&oldval>val&&oldval>mean) {
					if (f == -1)  { f = i; delta = oldval-prev.tvals[i-1];}
					else if (delta < oldval - prev.tvals[i - 1]) {
						delta = oldval - prev.tvals[i - 1];
						l = i;
					}
					trace(i);
				}
				oldoldval = oldval;
				oldval = val;
				i++;
			}
			if (f == -1) pos = 0; this.i = l;
			//pos  = .5 + (l + 1) / v.length * Math.sin(l * 2) * Math.cos(l * 2) * 2 * 0.5; //(x + 1) / 128 * sin(x) * 0.5; 0.1:25;0.2:50
			// ((x + 1) / 128 * sin(x * 2) * cos(x * 2)*10)
			// 1 / (1 + exp( -x)) - 0.5
			pos = (l + 1) / v.length * Math.sin(l * 2) * Math.cos(l * 2); 
		}
	}
	
	public function  find(t:Int):SpectrInfo {
		if (t == time) return this;
		else {
			try{
				if (t > time && next != null && t>=next.time) return next.find(t);
				else{
					if (t < time && prev != null && t<=prev.time) return prev.find(t);
					else return null;
				}
			} catch (msg : String) { 
				trace(msg);
				return null; 
			}
		}
	}
	/**
	 * function return position of peak
	 * @param	k from 0..30
	 * @return 0..1
	 */
	public function getPos(k:Int = 0):Float {
		if (k == 0) return pos + 0.5;
		else return 1 / (1 + Math.exp( -k * pos));
		
		//																			y :x
		// (x + 1) / 128 * sin(x * 2) * cos(x * 2);x:1..128		    			 //0.1:25; 0.2:50; 0.4:100
		// 1 / (1 + exp( -(2 * (x + 1) / 128 * sin(x * 2) * cos(x * 2)))) - 0.5; //0.1:50; 0.2:110
		// 1 / (1 + exp( -(5 * (x + 1) / 128 * sin(x * 2) * cos(x * 2)))) - 0.5; //0.1:20; 0.2:40
		// 1 / (1 + exp( -(10 * (x + 1) / 128 * sin(x * 2) * cos(x * 2)))) - 0.5;//0.1:10; 0.2:20; 0.4:50;
		// 1 / (1 + exp( -(30 * (x + 1) / 128 * sin(x * 2) * cos(x * 2)))) - 0.5;//0.3:10;
	}
	
	
	
}