package sound;
import flash.errors.Error;
import flash.media.Sound;
import flash.utils.ByteArray;

/**
 * ...
 * @author levserk
 */

class Fft 
{
		private var sampleLength:UInt;
		private var data:flash.Vector<Float>;
		public var spectr:flash.Vector<Float>;
		private var ba:ByteArray; 
		private var i:Int;
		
		public var oldsumIn:Float = -1;
		
		public function new(length:Int=512)	{
			sampleLength = length;
			data = new flash.Vector<Float>(sampleLength << 1, true);
			spectr = new flash.Vector<Float>(sampleLength);
			ba = new ByteArray();
		}
	 
		inline public function calcSpectrum(position:Int = 0, sound:Sound):flash.Vector<Float> {
			ba.position = 0;
			sound.extract(ba, sampleLength, position * 44.1);
			ba.position = 0;
			i = 0;
			while(ba.bytesAvailable>0) {	
				data[i] = ba.readFloat();
				data[i + sampleLength] = ba.readFloat();
				i += 1;
			}
			fft(data);				
			return spectr;
		}
		
		
		inline private function fft(dInOut:flash.Vector<Float>):Void{
			var i:Int, j:Int, n:Int, m:Int, mmax:Int, istep:Int;
			var tempr:Float, tempi:Float, wtemp:Float, theta:Float, wpr:Float, wpi:Float, wr:Float, wi:Float;
			var data:flash.Vector<Float> = new flash.Vector<Float>(dInOut.length * 2 + 1, true);
			i = dInOut.length;
			while (i-->0)
			{
				data[i * 2] = 0;
				data[i * 2 + 1] = dInOut[i];
			}
			n = dInOut.length << 1;
			j = 1;
			i = 1;
			while (i < n)
			{
				if (j > i)
				{
					tempr = data[i];
					data[i] = data[j];
					data[j] = tempr;
					tempr = data[i + 1];
					data[i + 1] = data[j + 1];
					data[j + 1] = tempr;
				}
				m = n >> 1;
				while ((m >= 2) && (j > m))
				{
					j -= m;
					m = m >> 1;
				}
				j += m;
				i += 2;
			}
			mmax = 2;
			while (n > mmax)
			{
				istep = 2 * mmax;
				theta = -2 * Math.PI / mmax;
				wtemp = Math.sin(0.5 * theta);
				wpr = -2 * wtemp * wtemp;
				wpi = Math.sin(theta);
				wr = 1;
				wi = 0;
				m = 1;
				while (m < mmax)
				{
					i = m;
					while (i < n)
					{
						j = i + mmax;
						tempr = wr * data[j] - wi * data[j + 1];
						tempi = wr * data[j + 1] + wi * data[j];
						data[j] = data[i] - tempr;
						data[j + 1] = data[i + 1] - tempi;
						data[i] += tempr;
						data[i + 1] += tempi;
						i += istep;
					}
					wtemp = wr;
					wr = wtemp * wpr - wi * wpi + wr;
					wi = wi * wpr + wtemp * wpi + wi;
					m += 2;
				}
				mmax = istep;
			}
			
			i = cast(dInOut.length * 0.5, Int);
			while (i-->0)
			{
				dInOut[i] = Math.sqrt(data[i * 2] * data[i * 2] + data[i * 2 + 1] * data[i * 2 + 1]);
				spectr[i] = dInOut[i];
			}	
		}
	
}