package ;

import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.geom.Point;

enum GameState {
	Paused;
	Playing;
}

enum Player {
	Human;
	AI;
}

class Main extends Sprite 
{
	var inited:Bool;
	
	private var platform1:Platform;
	private var platform2:Platform;
	private var ball:Ball;
	private var scorePlayer:Int;
	private var scoreAI:Int;
	private var scoreField:TextField;
	private var messageField:TextField;
	private var currentGameState:GameState;
	private var arrowKeyUp:Bool;
	private var arrowKeyDown:Bool;
	private var platformSpeed:Int;
	private var ballMovement: Point;
	private var ballSpeed: Int;

	/* ENTRY POINT */
	
	function resize(e) 
	{
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() 
	{
		if (inited) return;
		inited = true;
		
		platform1 = new Platform();
		platform2 = new Platform();
		ball = new Ball();
		scoreField = new TextField();
		messageField = new TextField();

		var scoreFormat:TextFormat = new TextFormat("Verdana", 24, 0xbbbbbb, true);
		var messageFormat:TextFormat = new TextFormat("Verdana", 18, 0xbbbbbb, true);

		initPlatform(platform1, 5, 200);
		initPlatform(platform2, 480, 200);	
		initBall(ball, 250, 250);		
		initTextField(scoreField, scoreFormat, 500, 30);		
		initTextField(messageField, messageFormat, 500, 450, "Press SPACE to start\nUse ARROW KEYS to move your platform");
		
		scorePlayer = 0;
		scoreAI = 0;
		arrowKeyUp = false;
		arrowKeyDown = false;
		platformSpeed = 7;
		setGameState(Paused);
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
		this.addEventListener(Event.ENTER_FRAME, everyFrame);

		ballSpeed = 7;
		ballMovement = new Point(0, 0);
	}

	private function initPlatform(platform:Platform, x:Int, y:Int):Void {
		platform.x = x;
		platform.y = y;
		this.addChild(platform);
	}

	private function initBall(ball:Ball, x: Int, y: Int): Void {
		ball.x = x;
		ball.y = y;
		this.addChild(ball);
	}

	private function initTextField(textfield: TextField, textformat: TextFormat, width: Int, y: Int, ?text: String): Void {
		textformat.align = TextFormatAlign.CENTER;
		textfield.width = width;
		textfield.y = y;
		textfield.defaultTextFormat = textformat;
		textfield.selectable = false;
		textfield.text = text;
		addChild(textfield);
	}
	
	private function setGameState(state:GameState):Void {
		currentGameState = state;
		updateScore();
		if (state == Paused) {
			messageField.alpha = 1;
		}else {
			messageField.alpha = 0;
			platform1.y = 200;
			platform2.y = 200;

			ball.x = 250;
			ball.y = 250;
			var direction: Int = (Math.random() > .5)?1:-1;
			var randomAngle: Float = (Math.random() * Math.PI / 2) - 45;
			ballMovement.x = Math.cos(randomAngle) * ballSpeed * direction;
			ballMovement.y = Math.sin(randomAngle) * ballSpeed;
		}
	}
	
	private function keyDown(event:KeyboardEvent):Void {
		if (currentGameState == Paused && event.keyCode == 32) { // Space
			setGameState(Playing);
		}else if (event.keyCode == 38) { // Up
			arrowKeyUp = true;
		}else if (event.keyCode == 40) { // Down
			arrowKeyDown = true;
		}
	}
	
	private function keyUp(event:KeyboardEvent):Void {
		if (event.keyCode == 38) { // Up
			arrowKeyUp = false;
		}else if (event.keyCode == 40) { // Down
			arrowKeyDown = false;
		}
	}

	private function bounceBall(): Void {
		var direction: Int = (ballMovement.x > 0) ? -1 : 1;
		var randomAngle: Float = (Math.random() * Math.PI /2) -45;
		ballMovement.x = direction * Math.cos(randomAngle) * ballSpeed;
		ballMovement.y = Math.sin(randomAngle) * ballSpeed;
	}
	
	private function everyFrame(event:Event):Void {
		if (currentGameState == Playing) {
			// player platform movement
			if (arrowKeyUp) {
				platform1.y -= platformSpeed;
			}
			if (arrowKeyDown) {
				platform1.y += platformSpeed;
			}
			// AI platform movement
			if (ball.x > 300 && ball.y > platform2.y + 70) {
				platform2.y += platformSpeed;
			}
			if (ball.x > 300 && ball.y < platform2.y + 30) {
				platform2.y -= platformSpeed;
			}
			// player platform limits
			if (platform1.y < 5) platform1.y = 5;
			if (platform1.y > 395) platform1.y = 395;
			// AI platform limits
			if (platform2.y < 5) platform2.y = 5;
			if (platform2.y > 395) platform2.y = 395;
			// ball movement
			ball.x += ballMovement.x;
			ball.y += ballMovement.y;
			// ball platform bounce
			if (ballMovement.x < 0 && ball.x < 30 && ball.y >= platform1.y && ball.y <= platform1.y + 100) {
				bounceBall();
				ball.x = 30;
			}
			if (ballMovement.x > 0 && ball.x > 470 && ball.y >= platform2.y && ball.y <= platform2.y + 100) {
				bounceBall();
				ball.x = 470;
			}
			// ball edge bounce
			if (ball.y < 5 || ball.y > 495) ballMovement.y *= -1;
			// ball goal
			if (ball.x < 5) winGame(AI);
			if (ball.x > 495) winGame(Human);
		}
	}
	
	private function updateScore():Void {
		scoreField.text = scorePlayer + ":" + scoreAI;
	}

	private function winGame(player: Player): Void {
		if (player == Human) {
			scorePlayer++;
		}
		else {
			scoreAI++;
		}
		setGameState(Paused);
	}

	/* SETUP */

	public function new() 
	{
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	public static function main() 
	{
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
		//
	}
}