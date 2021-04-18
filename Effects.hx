import hxd.snd.ChannelGroup;
import h3d.shader.Base2d;

class RNG extends hxsl.Shader {
	static var SRC = {
		function rand(co:Vec2):Float{
			return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
		}
	}
}

class RedShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var red:Float;
		function fragment() {
			pixelColor = texture.get(input.uv);
			pixelColor.r = red; // change red channel
		}
	}
}

class RngOpacityShader extends hxsl.Shader {
	static var SRC = {
		@:import RNG;
		@:import h3d.shader.Base2d;
		@param var texture:Sampler2D;
		@param var opacity:Float;
		function fragment() {
			pixelColor = texture.get(calculatedUV);
			var a = min(pixelColor.a, sign(opacity + rand(calculatedUV) - 1));
			pixelColor.a = a;
		}
	}
}

class TearShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@:import RNG;
		@param var texture:Sampler2D;
		@param var strength:Float;
		function fragment() {
			pixelColor = texture.get(input.uv);
			var n = step(atan(strength) / 2. * pixelColor.a, rand(calculatedUV));
			pixelColor.rgb = n * pixelColor.rgb + (1.-n) * rand(calculatedUV+1.); 
		}
	}
}


class Effects {
	static public function red(val:Float) {
		var shader = new RedShader();
		shader.red = val;
		return new h2d.filter.Shader(shader);
	}

	static public function tear(strength:Float) {
		var shader = new TearShader();
		shader.strength = strength;
		return new h2d.filter.Shader(shader);
	}

	static public function rngOpacity(bitmap:Bitmap):RngOpacityShader {
		var redShader = new Effects.RngOpacityShader();
		redShader.texture = bitmap.tile.getTexture();
		bitmap.addShader(redShader);
		return redShader;
	}
}

class Explosion extends Entity {
	var scaleMultiplier:Float;
	public function new(image:Image, source:Entity, radius:Float) {
		super(source.app);
		var bmp = new Bitmap(image.toTile().center(), this);
		scaleMultiplier = radius / bmp.tile.width;
		setPosition(source.x, source.y);
		rotation = Math.random(Math.PI*2);
		maxAge = 1;
		update(0);
	}

	override public function update(dt:Float) {
		super.update(dt);
		this.setScale(Math.atan(lifeTime) * scaleMultiplier);
		this.alpha = (1 - lifeTime)/maxAge;
	}
}
