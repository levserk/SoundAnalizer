package sound;

/**
 * ...
 * @author levserk
 */

class Interval 
{

	public var t1:Int;
	public var t2:Int;
	public var n:Int;  //count peaks
	public var meanA:Float;
	
	inline public function meanH():Float { return __meanH / (t2-t1)*step; }
	
	public var meanT:Float;
	public var c:Int;
	private var __meanH:Float;
	private var step:Int = 0;
	
	public var prev:Interval;
	public var next:Interval;
	
	private var speed:Int=-1;
	
	public function new(_t1:Int, _t2:Int, _n:Int, _meanA:Float, _meanH:Float, _meanT:Float,_prev:Interval=null) {
		t1 = _t1; t2 = _t2; n = _n; meanA = _meanA; __meanH = _meanH; meanT = _meanT; prev = _prev;
		c = Std.int((t2 - t1) / step); 
		step = Analizer.step;
	}
	
	inline public function addPeak(p:Peak):Void {
		t2 = p.time;
		n++;
		meanA = (meanA * (n - 1) + p.A ) / n;
		meanT = (meanT * (n - 1) + p.T ) / n;
		c += p.c;
		__meanH += p.meanH;
	}
	
	inline public function addInterval(i:Interval):Void {
		if (i.t1 < t1) t1 = i.t1; else	t2 = i.t2;
		meanA = (meanA * n + i.meanA * i.n) / (n + i.n);
		meanT = (meanT * n + i.meanT * i.n) / (n + i.n);
		n += i.n;
		__meanH += i.__meanH;
		c += i.c;
		speed = -1;
	}
	
	inline public function getSpeed():Float {
		if (speed <=0) speed = Std.int(10000 / meanT + meanA * 200 * (Std.string(n).length)+1 + meanH() * 150);
		if (speed == 0) 
		trace('wtf');
		return speed;
	}
	
	inline public function length():Int { return t2-t1; }
	
	public function find(t:Int):Interval {
		if (t1 <= t && t < t2) return this;
		else {
			if (next != null && t >= t2) return next.find(t);
			else { 
				if (prev != null && t < t1) return prev.find(t);
				else return null;
			}
		}
	}
	
	inline public function remove():Void {
		if (prev != null) prev.next = next;
		if (next != null) next.prev = prev;
	}
}