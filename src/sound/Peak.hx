package sound;
import flash.Memory;

/**
 * ...
 * @author levserk
 */

class Peak 
{

		public var time:Int;
		public var A:Float;
		public var H:Float;
		public var meanH:Float;
		public var T:Int;
		public var c:Int;
		public var next:Peak;
		public var prev:Peak;
		
		public function new(_time:Int, _A:Float, _H:Float, _T:Int,_meanH:Float,_c:Int,_prev:Peak=null) {
			time = _time; A = _A; H = _H; T = _T; meanH = _meanH; c = _c;
			prev = _prev;
			if (c == 0) 
			c = Std.int(T / Analizer.step);
		}
		
		inline public function _meanH():Float {
			return meanH / c;
		}
		
		public function find(t:Int):Peak {
			if (t == time) return this;
			else{
				if (t > time && next != null && next.time<=t) return next.find(t);
				else {
					if (t < time && prev != null && prev.time>=t) return prev.find(t);
					else return null;
				}
			}
		}
	
}