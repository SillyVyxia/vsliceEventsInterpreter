import backend.Mods;
import tjson.TJSON;
import flixel.tweens.FlxTween;
import psychlua.LuaUtils;
import flixel.math.FlxMath;
import backend.StageData;
import Std;
import Type;
import flixel.util.FlxTimer;
import Reflect;
import flixel.FlxObject;
import flixel.FlxCamera.FlxCameraFollowStyle;
import substates.GameOverSubstate;
import Math;

var eventsArray = [];
var ZoomCameraTween = null;
var FocusCameraTween = null;
var songSpeedTween = null;
var trueDefaultZoom = 1.05;
var vSpecialAnim = {boyfriend: false, dad: false, gf: false};
var defaultScrollSpeed = 1.0;
var camZoomingRate = 4;
var fakecamzooming = false;
var cameraBopMultiplier = 1.0;
var camHUDZoomingMult = 1.0;
var currentCameraZoom = 1.0;
var fakeCamFollow = null;
var isClassicTween = false;
var fakeFollowlerp = 0.04;
function customFocusOn(x, y) {
    FlxG.camera.scroll.set(x - FlxG.camera.width * 0.5, y - FlxG.camera.height * 0.5);
}
function updateLerp(elapsed:Float):Float {
    var adjustedLerp = 1.0 - Math.pow(1.0 - fakeFollowlerp * game.cameraSpeed * game.playbackRate, elapsed * 60);

    fakeCamFollow.x += (game.camFollow.x - fakeCamFollow.x) * adjustedLerp;
    fakeCamFollow.y += (game.camFollow.y - fakeCamFollow.y) * adjustedLerp;
}
function tweenCameraZoom(?zoom:Float = 1, ?duration:Float = 1, ?ease:String = 'linear')
{
    var fullZoom = trueDefaultZoom*zoom;
    if (ZoomCameraTween != null)
        ZoomCameraTween.cancel();
    if (ease.toUpperCase() == 'INSTANT' || duration == 0)
    {
        currentCameraZoom = fullZoom;
        game.defaultCamZoom = fullZoom;
    }
    else
    {
        ZoomCameraTween = FlxTween.num(currentCameraZoom, fullZoom, duration/game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
            onComplete: function()
            {
                currentCameraZoom = fullZoom;
                game.defaultCamZoom = fullZoom;
                ZoomCameraTween = null;
            }
        },
        function(num) {
            currentCameraZoom = num;
        });
    }
}
function vslicePlayAnim(char:Dynamic, anim:String, ?force:Bool = false)
{
    if (char == 'dad' || char == 'opponent' || char == 1) {
        game.dad.playAnim(anim, force);
        game.dad.specialAnim = true;
        game.dad.skipDance = true;
        vSpecialAnim.dad = true;
    }
    else if (char == 'gf' || char == 'girlfriend' || char == 2) {
        game.gf.playAnim(anim, force);
        game.gf.specialAnim = true;
        game.gf.skipDance = true;
        vSpecialAnim.gf = true;
    }
    else {
        game.boyfriend.playAnim(anim, force);
        game.boyfriend.specialAnim = true;
        game.boyfriend.skipDance = true;
        vSpecialAnim.boyfriend = true;
    }
}
function tweenCameraPosition(?x:Float = 0, ?y:Float = 0, ?duration:Float = 1, ?ease:String = 'CLASSIC') {
    if (FocusCameraTween != null)
        FocusCameraTween.cancel();
    game.camFollow.x = x;
    game.camFollow.y = y;
    isClassicTween = false;
    if (ease.toUpperCase() == 'INSTANT') {
        fakeCamFollow.x = x;
        fakeCamFollow.y = y;
    } else if (ease.toUpperCase() == 'CLASSIC') {
        isClassicTween = true;
    } else {
        FocusCameraTween = FlxTween.tween(fakeCamFollow, {x: x, y: y}, duration / game.playbackRate, {ease: LuaUtils.getTweenEaseByString(ease),
            onComplete: function()
            {
                fakeCamFollow.x = x;
                fakeCamFollow.y = y;
                FocusCameraTween = null;
            }
        });
    }
}
function changeCamFocus(char:Dynamic, ?duration:Float = 1, ?ease:String = 'CLASSIC', ?x:Float = 0, ?y:Float = 0) {
    var fullX = 0;
    var fullY = 0;
    var c = Std.string(char).toLowerCase();
    if (c == 'gf' || c == 'girlfriend' || c == '2')
    {
        fullX = game.gf.getMidpoint().x;
        fullY = game.gf.getMidpoint().y;
        fullX += game.gf.cameraPosition[0] + game.girlfriendCameraOffset[0];
        fullY += game.gf.cameraPosition[1] + game.girlfriendCameraOffset[1];
    }
    else if (c == 'dad' || c == 'opponent' || c == '1')
    {
        fullX = game.dad.getMidpoint().x + 150;
        fullY = game.dad.getMidpoint().y - 100;
        fullX += game.dad.cameraPosition[0] + game.opponentCameraOffset[0];
        fullY += game.dad.cameraPosition[1] + game.opponentCameraOffset[1];
    }
    else
    {
        fullX = game.boyfriend.getMidpoint().x - 100;
        fullY = game.boyfriend.getMidpoint().y - 100;
        fullX += game.boyfriend.cameraPosition[0] + game.boyfriendCameraOffset[0];
        fullY += game.boyfriend.cameraPosition[1] + game.boyfriendCameraOffset[1];
    }
    fullX += x;
    fullY += y;
    tweenCameraPosition(fullX, fullY, duration, ease);
}
function checkSpecialAnims()
{
    if (vSpecialAnim.dad && game.dad.isAnimationFinished()) {
        game.dad.skipDance = false;
        vSpecialAnim.dad = false;
        game.dad.dance();
    }
    if (vSpecialAnim.gf && game.gf.isAnimationFinished()) {
        game.gf.skipDance = false;
        vSpecialAnim.gf = false;
        game.gf.dance();
    }
    if (vSpecialAnim.boyfriend && game.boyfriend.isAnimationFinished()) {
        game.boyfriend.skipDance = false;
        vSpecialAnim.boyfriend = false;
        game.boyfriend.dance();
    }
}
function triggerVSliceEvent(name, values, strumTime):Void
{
    game.callOnScripts("onVSliceEvent", [name, values, strumTime]);
    switch(name) {
        case "FocusCamera":
            var durSeconds = (Conductor.stepCrochet * (values.duration ?? 4) / 1000);
            if (values == 2) 
                values = {char: 2};
            else if (values == 1)
                values = {char: 1};
            else if (values == 0)
                values = {char:0};
            changeCamFocus(values.char ?? 0, durSeconds, values.ease ?? 'CLASSIC', values.x ?? 0, values.y ?? 0);
        case "ZoomCamera":
            tweenCameraZoom(values.zoom, Conductor.stepCrochet * values.duration / 1000, values.ease);
        case "PlayAnimation":
            vslicePlayAnim(values.target, values.anim, values.force);
        case "ScrollSpeed":
            if (songSpeedType != 'constant') {
                var newValue = values.absolute ? (values.scroll * ClientPrefs.getGameplaySetting('scrollspeed')) : (defaultScrollSpeed * values.scroll * ClientPrefs.getGameplaySetting('scrollspeed'));
                if (songSpeedTween != null)
                    songSpeedTween.cancel();
                if (values.ease == 'INSTANT')
                    game.songSpeed = newValue;
                else
                {
                    var durSeconds = Conductor.stepCrochet * values.duration / 1000;
                    songSpeedTween = FlxTween.tween(game, {songSpeed: newValue}, durSeconds/game.playbackRate, {ease: LuaUtils.getTweenEaseByString(values.ease),
                        onComplete: function()
                        {
                            game.songSpeed = newValue;
                            songSpeedTween = null;
                        }
                    });
                }
            }
        case "SetCameraBop":
            camZoomingRate = values.rate;
            game.camZoomingMult = values.intensity;
            camHUDZoomingMult = values.intensity;
    }
    game.callOnScripts("onVSliceEventPost", [name, values, strumTime]);
}
function onCreatePost()
{
    var modPath = Mods.currentModDirectory;
    var songPath = Paths.formatToSongPath(game.songName);
    var jsonToUse = null;
    jsonToUse = Paths.getTextFromFile(modPath + '/data/' + songPath + '/vslice-events.json');
    if (jsonToUse == null) {
        this.destroy();
        return;
    }
    
    var parsedJson = TJSON.parse(jsonToUse);
    eventsArray = parsedJson.events;
    if (eventsArray == null) {
        this.destroy();
        return;
    }
    var eventsPushed = [];
    for (event in eventsArray) {
        var name = event.e;
        if (!eventsPushed.contains(name)) {
            game.startLuasNamed('vslice_events/' + name + '.lua');
            game.startHScriptsNamed('vslice_events/' + name + '.hx');
            eventsPushed.insert(eventsPushed.length, name);
            game.callOnScripts("onVSliceEventPushedUnique", [name, event.v]);
        }
        game.callOnScripts("onVSliceEventPushed", [name, event.v]);
    }

    createGlobalCallback('charPlayAnim', vslicePlayAnim);
    createGlobalCallback('tweenCameraZoom', tweenCameraZoom);
    createGlobalCallback('tweenCameraToChar', changeCamFocus);
    createGlobalCallback('tweenCameraPos', tweenCameraPosition);
    createGlobalCallback('setCameraPos', function(x, y){
        fakeCamFollow.setPosition(x, y);
    });
    createGlobalCallback('getCameraPosX', function(){
        return fakeCamFollow.x;
    });
    createGlobalCallback('getCameraPosY', function(){
        return fakeCamFollow.y;
    });
    createGlobalCallback('triggerVSliceEvent', function(name, values){
        triggerVSliceEvent(name, values, Conductor.songPosition);
    });
    createGlobalCallback('setCameraZoom', function(zoom){
        currentCameraZoom = zoom;
    });
    createGlobalCallback('getCameraZoom', function(){
        return currentCameraZoom;
    });
    var stageData = StageData.getStageFile(PlayState.SONG.stage);
    trueDefaultZoom = stageData.defaultZoom;
    currentCameraZoom = trueDefaultZoom;
    defaultScrollSpeed = game.songSpeed;
    fakeCamFollow = new FlxObject(0, 0, 1, 1);
    fakeCamFollow.setPosition(game.camFollow.x, game.camFollow.y);
    FlxG.camera.follow(fakeCamFollow, FlxCameraFollowStyle.LOCKON, 99.9);
    add(fakeCamFollow);
}
function onUpdatePost(elapsed)
{
    if (game.endingSong) return;
    if (eventsArray[0] != null) {
        if (Conductor.songPosition >= eventsArray[0].t) {
            triggerVSliceEvent(eventsArray[0].e, eventsArray[0].v, eventsArray[0].t);
            eventsArray.remove(eventsArray[0]);
        }
    }
    game.isCameraOnForcedPos = true;
    game.camZooming = false;

    cameraBopMultiplier = FlxMath.lerp(1.0, cameraBopMultiplier, 0.95);
    var zoomPlusBop = currentCameraZoom * cameraBopMultiplier;
    FlxG.camera.zoom = zoomPlusBop;
    game.camHUD.zoom = FlxMath.lerp(1, game.camHUD.zoom, 0.95);

    FlxG.camera.followLerp = 99.9;
    if (isClassicTween)
        updateLerp(elapsed);
}
function onBeatHit()
{
    if (FlxG.camera.zoom < (1.35 * game.defaultCamZoom) && camZoomingRate > 0 && curBeat % camZoomingRate == 0) {
        cameraBopMultiplier = 0.015 * game.camZoomingMult + 1;
        game.camHUD.zoom += 0.015 * camHUDZoomingMult * 2;
    }
    checkSpecialAnims();
}
function onCountdownTick(_, tick)
{
    checkSpecialAnims();
}
function onGameOver()
{
    tweenCameraPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 6), 1, 'INSTANT');
    eventsArray = [];
}
function onGameOverStart()
{
    var gameOverInst = GameOverSubstate.instance;
    FlxG.camera.scroll.set();
    FlxG.camera.target = null;
    var fullX = gameOverInst.boyfriend.getGraphicMidpoint().x + gameOverInst.boyfriend.cameraPosition[0];
    var fullY = gameOverInst.boyfriend.getGraphicMidpoint().y + gameOverInst.boyfriend.cameraPosition[1];
    tweenCameraPosition(fullX, fullY, 3, 'CLASSIC');
    customFocusOn(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
    FlxG.camera.follow(fakeCamFollow, FlxCameraFollowStyle.LOCKON, 99.9);
}
function onEndSong()
{
    eventsArray = [];
}
