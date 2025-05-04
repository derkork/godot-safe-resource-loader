# Godot Safe Resource Loader

_This library is still quite new and has not seen much use yet. While it works reasonably well, there may still be bugs and security issues. Please report any issues you find._

<!--suppress HtmlDeprecatedAttribute -->
<p align="center"><img height="64" src="icon.svg" width="64"/></p>

## What is Godot Safe Resource Loader?

Godot Safe Resource Loader is a small library that allows you to safely load `.tres` resource files from unknown sources without risking your player's security. It does this by scanning the resource file for embedded GDScripts before loading it, and then only loading the resource if no GDScripts are found. The main use case for this is to allow your users to share savegames and load them without risking that they contain malicious code.


## Installation

Installation is very straightforward, you can download the library through the godot asset lib. Alternatively, you can download the latest release from the [releases page](releases/) and unzipping the contents into your project. The library code is located in `addons/safe_resource_loader/`. You can also find an example in the `safe_resource_loader_example/` folder. The example folder is not required so you can choose to not import it into your project. Finally go to `Project -> Project Settings -> Plugins` and enable the plugin.


## Usage

The plugin provides a drop-in-replacement for the `ResourceLoader.load` function. You can use it like this:

```gdscript
var resource = SafeResourceLoader.load("user://path/to/saved_game.tres")
```

If you're using C# you will have to first load the script and then call the load method on it:

```cs
var loader = ResourceLoader.Load("res://addons/safe_resource_loader/safe_resource_loader.gd") as Script;
var resource = loader.Call("load", "user://path/to/saved_game.tres");
```

This will scan the resource for embedded GDScripts and only load it if none are found. If embedded GDScripts are found, a warning will be printed and this function returns `null`. Note that this function will only load from paths outside the `res://` folder (e.g. saved games are usually stored in the `user://` folder). Loading resources that are under your control with this does not make any sense and in addition will not work once you export the game, as resources inside the `res://` folder cannot be accessed by file system scripts after export.

## Example Project

There is an example project in the `safe_resource_loader_example` folder. You can run it and then try to load a safe and a "malicious" resource using this library and using Godot's built-in `ResourceLoader` and see the results. The "malicious" resource will open a popup when loaded using Godot's `ResourceLoader` but not when loaded using this library.


## FAQ

### Why is this necessary?

Godot's text based resource format makes it easy to embed malicious scripts into resource files. This is a problem if you want to allow your users to share savegames, as they could potentially contain malicious code. These scripts will execute immediately when you load the resource using `ResourceLoader.load` without giving you any chance to intercept this.

### How does it work?

The addon first reads in the text file and parses it with its own parser implementation. This custom parser will not instantiate any scripts while parsing the file, so it cannot be attacked in the same way as the built-in resource loader. After parsing the file, the addon checks whether there are embedded resources of type `GDScript` in the file before feeding the file to Godot's `ResourceLoader`. It also verifies that all external resources originate from the `res://` path, so that you cannot inject scripts by putting them next to the resource file. If any of these checks fail, the resource is not loaded and a warning is printed.

### Is this secure?

The current implementation is preventing some currently known attack vectors. However it is basically a blacklist-based approach and some clever person might find a way of circumventing it in which case the library will need to be patched to prevent this new attack. Ideally Godot would provide a way to load resources in a sandboxed environment that does not allow GDScript execution, so this library would not be necessary.

### This is a terrible idea, I know five ways to break this already!

I am fully open to the possibility that this may not secure enough and that there may be ways to circumvent this. However it is hard to defend against attacks you don't know. So if you are a security expert and have some ideas on how to better implement this, please reach out and open an issue! 

### Why not just use JSON or another format instead of resources?

Resources provide excellent support for storing/loading large graphs of nested objects and keeping references between these objects intact. This is very useful for savegames, as you can simply build a nice object graph in your game and then save / load it with a single line of code. If you want to do the same thing with JSON you will need to manually serialize/deserialize all objects into JSON structures and also find a way of keeping references within the object graph intact. This is a lot of work, just to replicate something that resources already provide out of the box. I therefore think, that using this library is an acceptable compromise between security and implementation effort.

### Do I really need to bother with this?

You will need to look at how popular the game is and the incentive for a potential attacker to go to through the trouble of making a malicious savegame and distributing it to your game's player base. For many games this is probably not worth the effort - neither for you nor for a potential attacker. However if your game is popular enough, that it is likely to be a target for hackers, it may be worth considering how you can protect your users from malicious savegames. 

Another reason why you may want to consider thinking about this, is that injecting scripts can also be used for cheating. If you have a competitive multiplayer game, you may want to prevent players from injecting scripts the game through savegames that give them an unfair advantage.

Using this library is one way of doing this. You can also go all in and write a custom serialization system using JSON, XML or another format that doesn't allow for embedded scripts. There are several options. Pick one that provides the best balance between required security and development effort for your situation.

### Why is the icon looking so hideous?

Because I'm a programmer, not a designer. If you want to contribute a better icon, a PR is always welcome.
