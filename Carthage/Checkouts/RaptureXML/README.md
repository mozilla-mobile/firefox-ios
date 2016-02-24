RaptureXML is a simple, block-based XML library for the iOS platform that provides an expressive API that makes XML processing freakin' fun for once in my life.

# Why do we need *another* XML library? #

You tell me.  Processing XML in Objective-C is an awful, frustrating experience and the resulting code is never readable.  I'm tired of it! RaptureXML solves this by providing a *powerful* new interface on top of libxml2.  Imagine for a minute the code you'd write to process the XML for a list of baseball team members, retrieving their numbers, names, and positions using your favorite XML processing library.  Now, take a look at how you do it with RaptureXML:

	RXMLElement *rootXML = [RXMLElement elementFromXMLFile:@"players.xml"];
	
	[rootXML iterate:@"players.player" usingBlock: ^(RXMLElement *e) {
		NSLog(@"Player #%@: %@", [e attribute:@"number"], [e child:@"name"].text);
	}];    

RaptureXML changes the game when it comes to XML processing in Objective-C.  As you can see from the code, it takes only seconds to understand what this code does.  There are no wasted arrays and verbose looping you have to do.  The code is a breeze to read and maintain.

I don't think any more needs to be said.

# Adding RaptureXML to Your Project #

The recommended way to add RaptureXML to your project is through CocoaPods. Simply add 'RaptureXML' into your Podfile.

To install manually, there's just a few simple steps:

  * Copy the RaptureXML/RaptureXML folder into your own project and import "RXMLElement.h" somewhere (e.g., your PCH file).
  * Link in libz.dylib to your target.
  * Link in libxml2.dylib to your target.
  * In your build settings, for the key "Header Search Paths", add "$(SDK_DIR)"/usr/include/libxml2

RaptureXML supports ARC. You are free to use any version of LLVM or gcc as well! (Though you should be using LLVM by now.)

# ARC isn't just supported, it's required!

RaptureXML supports ARC.  In fact, it only supports ARC.  If you're still running a project that doesn't use ARC, RaptureXML won't be your cup of tea.

# Getting Started #

RaptureXML processes XML in two steps: load and path.  This means that you first load the XML from any source you want such as file, data, or string.  Then, you simply use its query language to find what you need.

You can load the XML with any of the following constructors:

	RXMLElement *rootXML = [RXMLElement elementFromXMLString:@"...my xml..." encoding:NSUTF8StringEncoding];
	RXMLElement *rootXML = [RXMLElement elementFromXMLFile:@"myfile.xml"];
	RXMLElement *rootXML = [RXMLElement elementFromXMLFilename:@"myfile" elementFromXMLFilename:@"xml"];
	RXMLElement *rootXML = [RXMLElement elementFromXMLData:myData];

These constructors return an RXMLElement object that represents the top-level tags. Now, you can query the data in any number of ways.

Let's pretend your XML looks like this:

	<team year="2011" name="New York Mets">
		<players>
			<coach>
				<name>Terry Collins</name>
				<year>1</year>
			</coach>
        
			<player number="7">
				<name>Jose Reyes</name>
				<position>SS</position>
			</player>
        
			<player number="16">
				<name>Angel Pagan</name>
				<position>CF</position>
			</player>
        
			<player number="5">
				<name>David Wright</name>
				<position>3B</position>
			</player>
			
			...
			
		</players>
	</team>

First, we'd load the XML:

	RXMLElement *rootXML = [RXMLElement elementFromXMLFile:@"players.xml"];

We can immediately query the top-level tag name:

	rootXML.tag --> @"team"

We can read attributes with:

	[rootXML attribute:@"year"] --> @"2011"
	[rootXML attribute:@"name"] --> @"New York Mets"

We can get the players tag with:

	RXMLElement *rxmlPlayers = [rootXML child:@"players"];

If we like, we can get all the individual player tags with:

	NSArray *rxmlIndividualPlayers = [rxmlPlayers children:@"player"];

From there, we can process the individual players and be happy.  Now, this is already much better than any other XML library we've seen, but RaptureXML can use query paths to make this ridiculously easy.  Let's use query paths to improve the conciseness our code:

	[rootXML iterate:@"players.player" usingBlock: ^(RXMLElement *player) {
		NSLog(@"Player: %@ (#%@)", [player child:@"name"].text, [player attribute:@"number"]);
	}];    

Your block is passed an RXMLElement representing each player in just one line!  Alternatively, you could have shortened it with:

	[rootXML iterate:@"players.player" usingBlock: ^(RXMLElement *player) {
		NSLog(@"Player: %@ (#%@)", [player child:@"name"], [player attribute:@"number"]);
	}];    

This also works because RXMLElement#description returns the text of the tag. Query paths are even more powerful with wildcards.  Let's say we wanted the name of every person on the team, player or coach.  We use the wildcard to get it:

	[rootXML iterate:@"players.*.name" usingBlock: ^(RXMLElement *name) {
		NSLog(@"Name: %@", name.text);
	}];

The wildcard processes every tag rather than the one you would've named.  You can also use the wildcard to iterate all the children of an element:

	[rootXML iterate:@"players.coach.*" usingBlock: ^(RXMLElement *e) {
		NSLog(@"Tag: %@, Text: %@", e.tag, e.text);
	}];

This gives us all the tags for the coach.  Easy enough?

# XPath #

If you don't want to use the custom RaptureXML iteration query syntax, you can use the standard XPath query language as well.  Here's how you query all players with XPath:

	[rootXML iterateWithRootXPath:@"//player" usingBlock: ^(RXMLElement *player) {
		NSLog(@"Player: %@ (#%@)", [player child:@"name"], [player attribute:@"number"]);
	}];    

And remember, you can also test attributes using XPath as well. Here's how you can find the player with #5:

	[rootXML iterateWithRootXPath:@"//player[@number='5']" usingBlock: ^(RXMLElement *player) {
		NSLog(@"Player #5: %@", [player child:@"name"]);
	}];    

Note that you can only use XPath from the document root and it won't matter what RXMLElement you have.  If you have a derived RXMLElement, you can still build from the document root. If you're not familiar with XPath, you can use this [handy guide](http://www.w3schools.com/xpath/xpath_syntax.asp).

# Namespaces #

Namespaces are supported for most methods, however not for iterations.  If you want to use namespaces for that kind of thing, use the -children method manually.  When specifying namespaces, be sure to specify the namespace URI and *not* the prefix.  For example, if your XML looked like:

	<team xmlns:sport="*" sport:year="2011" sport:name="New York Mets">
		...
	</team>

You would access the attributes with:

	NSLog(@"Team Name: %@", [e attribute:@"name" inNamespace:@"*"]);

# RubyMotion Support #

RaptureXML is easily integrated into RubyMotion!  [Here's how.](http://raptureinvenice.com/797/)

# Unit Tests as Documentation #

You can see the full usage of RaptureXML by reading the unit tests in the project.  Not only does it show you all the code, but you'll know it works! (You can run the unit tests by pressing Command-U in XCode)

# Who Created RaptureXML? #

RaptureXML was created by John Blanco <john.blanco@raptureinvenice.com> of Rapture In Venice because he got sick of using all of the bizarre XML solutions for iPhone development.  If you like this code and/or need an iOS consultant, get in touch with me via my website, [Rapture In Venice](http://raptureinvenice.com).
