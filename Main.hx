
@:access(h2d.Scene)
class Main extends App {
	public var u:Mob;
	public var entities:Array<Entity> = [];
	public var items:Array<Item> = [];
	public var h = 2048;
	public var w:Int;
	public var t = 0.;
	public var pause = false;
	public var cg:Graphics;

	var win:sdl.Window;

	override function init() {
		Res.initLocal();
		loadArmory();

		win = @:privateAccess hxd.Window.getInstance().window;

		w = int(h * Math.sin(Math.PI / 3) * 2);

		engine.backgroundColor = 0xFFAAAAAA;

		s2d.renderer.defaultSmooth = true;
		Res.images.ubody.toTile().center();
		var blob = Res.images.cursor.toBitmap();
		s2d.events.defaultCursor = Cursor.Custom(new Cursor.CustomCursor([blob], 0, 4, 4));

		s2d.scaleMode = ScaleMode.LetterBox(w, h);
		win.resize(int(w / 2), int(h / 2));
		win.title = "Retrofabricator";
		win.center();

		Window.getInstance().displayMode = sdl.Window.DisplayMode.Borderless;

		var controlsMark = new Bitmap(Res.images.controls_big.toTile(), s2d);
		controlsMark.setScale(2);

		u = new Mob(this);
		u.setPosition(500, 500);
		u.faction = US;

		weapons.contra.equip(u, 2);
		weapons.claw.equip(u, 1);
		//weapons.contra.equip(u, 2);

		armors.uarmor.equip(u);
		boots.swap.equip(u);

		//new Bitmap(Res.images.cog.toTile(), s2d);
		new Bitmap(Res.images.cube.toTile().center(), s2d).setPosition(w / 2, h / 2);

		var item = new Item(this, weapons.plus_one);
		item.setPosition(1500,500);
		item.completeness = 30;

		/*item = new Item(this, weapons.long_revolver);
		item.setPosition(500,1000);
		item.completeness = 2;*/

		cg = new h2d.Graphics(s2d);
		cg.lineStyle(5, 5, 1.);
		cg.color = new Vector(1,1,1,1);

		//spawnZombie();

		//s2d.filter = Effects.red(0.5);		
	}

	public function closestCraftingItem(p:Vector):Item{
		return Lambda.fold(items, (i:Item, r:Item) -> (i.completeness<1 && (r == null || r.pos().distance(p) > i.pos().distance(p))?i:r), null);
	}

	public function closestPossibleItem(p:Vector):Item{
		return Lambda.fold(items, (i:Item, r:Item) -> (i.completeness>1 && (r == null || r.pos().distance(p) > i.pos().distance(p))?i:r), null);
	}


	override function update(dt:Float) {
		t += dt;
		cg.clear();

		if (Key.isPressed(Key.P))
			togglePause();

		if (!pause) {
			for (e in entities)
				e.update(dt);
			s2d.ysort(0);
		}

		if(Math.random() * (Math.pow(items.length,2)+1) * 1 < dt){
			spawnItem();
		}
		
	}

	function spawnItem(){
		var item = new Item(this, Armory.spawnedItems[int(Math.random(Armory.spawnedItems.length))]);
		item.completeness = 3 + Math.random(20);
		item.setPosition(Math.random()*w, Math.random()*h);
	}

	public function togglePause() {
		pause = !pause;
	}

	static function main() {
		new Main();
	}
}

