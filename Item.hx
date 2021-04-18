class Item extends Entity {
	public var completeness = 0.;
	public var bitmap:Bitmap;
	public var equipment:Equipment;

	var shader:Effects.RngOpacityShader;

	public function new(app:Main, equipment:Equipment) {
		super(app);
		app.items.push(this);
		this.equipment = equipment;
		bitmap = new Bitmap(equipment.image.toTile().center(), this);
	}

	public function endFabrication() {
		completeness = 0.99;
		shader = Effects.rngOpacity(bitmap);
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (shader != null)
			shader.opacity = completeness;
		if (completeness < 1) {
			if (Math.random() < dt) {
				spawnZombie();
			}

			var cg = app.cg;

			for (i in 0...3) {
				cg.lineStyle(Math.random() * 3, randomBWColor(), Math.random());
				cg.moveTo(x, y);
				var midX = (x + app.w / 2) / 2;
				var midY = (y + app.h / 2) / 2;
				cg.cubicCurveTo(x
					+ Math.random() * 400
					- 200, y
					+ Math.random() * 400
					- 200, midX
					+ Math.random() * 200
					- 100,
					midY
					+ Math.random() * 200
					- 100, app.w / 2
					+ 200 * (Math.random() - 0.5), app.h / 2
					+ 200 * (Math.random() - 0.5));
				cg.lineTo(app.w / 2, app.h / 2);
			}
		}

		if (completeness > 1) {
			completeness -= dt;
			var n = (2. + Math.sin(lifeTime / completeness * 100)) / 3.;
			bitmap.alpha = n * 0.8;
			setScale(0.8 + n * 0.4);
			if (completeness <= 1) {
				dispose();
			}
		}
	}

	function randomColor() {
		return int(Math.random(0xff)) * 0xff000000 + int(Math.random(0xff)) * 0xff0000 + int(Math.random(0xff)) * 0xff00 + 0xff;
	}

	function randomBWColor() {
		var v = int(Math.random(0xff));
		return 0x010101 * v;
	}

	function randomColorVec() {
		return new Vector(Math.random(), Math.random(), Math.random(), 1);
	}

	function spawnZombie() {
		var m = new Mob(app);
		boots.zlegs.equip(m);
		helmets.zhelmet.equip(m);
		armors.zarmor.equip(m);
		weapons.claw.equip(m, 1);
		weapons.claw.equip(m, 2);
		m.x = x;
		m.y = y;
		m.vel = new Vector(Math.random() - 0.5, Math.random() - 0.5).normalized();
		m.spawning = 1.;
		if(Math.random()<0.3)
			weapons.pistol.equip(m, 1);
		/*var d = 300;
			z.setPosition(d*(Math.random()-0.5)+x, d*(Math.random()-0.5)+y); */
	}

	override public function dispose() {
		super.dispose();
		app.items.remove(this);
	}
}
