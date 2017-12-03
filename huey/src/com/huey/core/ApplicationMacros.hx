package com.huey.core;
import com.huey.macros.*;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;

using com.huey.macros.MacroTools;

/**
 * ...
 * @author Newgrounds.com, Inc.
 */

class ApplicationMacros
{

	@:macro public static function buildApplication() : Array<Field> {
		var cl : ClassBuilder = ClassBuilder.createFromContext();
		
		var xml;
		if(cl.getMeta(":xml") != null) {
			var xmlPath : String = cl.getMeta(":xml").params[0].extractString();
			if(xmlPath != null) {
				xml = new haxe.xml.Fast( Xml.parse(sys.io.File.getContent(xmlPath)).firstElement() );
				Context.addResource("applicationData", sys.io.File.getBytes(xmlPath));
			}
		}

		var appClass = cl.name; // MIKE: Why doesn't fullClassPath work here?
		var field = new FieldInfo("main");
		field.pos = Context.currentPos();
		field.access = [AStatic, APublic];
		field.kind = FFun({
			params:	[],
			ret:	null,
			args:	[],
			expr:	macro {
				// If this is a worker thread, run its entry point
				// TODO: Should this probably be in Thread class?
				var worker = flash.system.Worker.current;
				if(!worker.isPrimordial) {
					var entryPoint : String = worker.getSharedProperty("entryPoint");
					var i = entryPoint.lastIndexOf(".");
					var className = entryPoint.substr(0, i);
					var methodName = entryPoint.substr(i+1);
					Reflect.field(Type.resolveClass(className), methodName)();
					return;
				} else {
				// else run main application
					_app = new $appClass();
				}
			}
		});
		cl.addField(field);
		
		field = new FieldInfo("BUILD_TIME");
		field.pos = Context.currentPos();
		field.access = [AStatic, APublic, AInline];
		field.kind = FVar(null, macro Date.now());
		cl.addField(field);
		
		if(cl.getMeta(":version") != null) {
			field = new FieldInfo("VERSION");
			field.pos = Context.currentPos();
			field.access = [AStatic, APublic, AInline];
			var version : String = cl.getMeta(":version").params[0].extractString();
			field.kind = FVar(null, {expr: EConst(CString(version)), pos: Context.currentPos()});
			cl.addField(field);
		}
		
		var es : Array<Expr> = [];
		for(assetData in xml.node.assets.nodes.asset) {
			var assetName = {expr:EConst(CString(assetData.att.name)), pos: Context.currentPos()};
			es.push(macro assetManager.registerAsset( new Asset($assetName, Internal($assetName)) ));
			Context.addResource(assetData.att.name, sys.io.File.getBytes(assetData.att.source));
		}
		
		field = new FieldInfo("registerAssets");
		field.pos = Context.currentPos();
		field.access = [APrivate, AOverride];
		field.kind = FFun({
			params: [],
			ret:	null,
			args:	[],
			expr:	{expr: EBlock(es), pos: Context.currentPos()},
		});
		cl.addField(field);
		
		field = new FieldInfo("_app");
		field.pos = Context.currentPos();
		field.access = [AStatic, APrivate];
		field.kind = FVar(null);
		cl.addField(field);
		
		/*field = new FieldInfo("buildUI");
		field.access = [APrivate, AOverride];
		field.kind = FMethod( {
			
		} );
		cl.addField(field);*/

		return cl.fields();
	}
	
}