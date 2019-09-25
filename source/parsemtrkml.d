
import std.algorithm;
import std.array;
import std.ascii;
import std.datetime.stopwatch;
import std.file;
import std.getopt;
import std.path;
import std.regex;
import std.stdio;

import arsd.dom;
import arsd.characterencodings;

//Combines KML (Google Keyhole Markup Language) files with Placemarks
//for the same route spread across multiple files into a single KML
//for that route. It will identify all routes in the input files and
//create a new file for each new route that it comes across. 
void main(string[] args)
{ 	
	//string[] files = ["mtrsrs.xml", "mtrsr_l.kml", "mtrov_sr_l.kml"];
	string[] inputFiles;
	string routeType;
	string outputPath;
	
	arraySep = ",";					//defined in getopts

	auto helpInformation = getopt(args, 
		std.getopt.config.required,
		"input|i", "List of .kml files containing <Placemark> tags", &inputFiles,
		std.getopt.config.required, 
		"type|t", "Type of MTR, either VR, SR, or IR", &routeType,
		std.getopt.config.required,
		"output|o", "Output folder", &outputPath);

	if(helpInformation.helpWanted)
	{
		defaultGetoptPrinter("Usage: parsemtrkml -t SR -i mtrsrs.kml,mtrsr_l.kml,mtrov_sr_l.kml -o output", helpInformation.options);
		return;
	}

	outputPath = buildNormalizedPath(outputPath);
	
	if(!outputPath.isDir)
	{
		outputPath.mkdir;
	}

	char[] outputBuffer;
	char[][] foundRoutes;					//as we find a new route in the XML, we add it to this list
	char[][] outputFiles;					//list of output files
	StopWatch sw = StopWatch(AutoStart.no);	//measure execution time
	sw.start();

	//strip out comments
	auto re1 = regex(`<!.*?]]>`, "gs");

	//find missing SR, VR or IR in <name> tags
	auto re2 = regex(`(?<=<name>)(?=(\d{3,4}.{0,1})</name>)`, "g");

	//strip out styles
	auto re3 = regex(`<Style>.*?</Style>`, "gs");

	//strip out descriptions
	auto re4 = regex(`<description>.*?</description>`, "gs");

	string ngaURL = "https://gis.geo.nga.mil/GoogleEarth/kml_icons/dafif";

	//parse each of the input files
	foreach(kmlFile; inputFiles)
	{
		//skip over incorrect files
		if(!kmlFile.exists)
		{
			writeln("File ", kmlFile, " not found. ");
			continue;
		}

		writeln("Processing ", routeType, " route file ", kmlFile);
		
		//kmlPoints is the pre-processed KML file
		auto kmlPoints = readText(kmlFile)
							.replace(ngaURL, ".")
							.replaceAll(re1,"")
							.replaceAll(re2,routeType)
							.replaceAll(re3,"")
							.replaceAll(re4,"");

		//create DOM
		auto doc = new Document();

		doc.parseUtf8(kmlPoints, true, false);
		doc.parseSawComment = delegate(string){ return false; };
		
		//Find placemarks
		auto placemarks = doc.getElementsByTagName("Placemark");
		foreach(placemark; placemarks)
		{
			auto routeName = placemark.getElementsByTagName("name")[0].innerHTML();
			//writeln(routeName);

			//Check for alphaNumeric to prevent directory escape attacks with malicious XML
			if(all!isAlphaNum(routeName))
			{
				string fileName = outputPath ~ "/" ~ routeName ~ ".kml";
			  	if(isNewRoute(foundRoutes, routeName))
			 	{
					//create the new file and write header to it
					foundRoutes ~= routeName.dup;	//need this to ensure we only write header once
					outputFiles ~= fileName.dup;	//need these later to add footer
					
					//write header
					//writeln("Found route: ", fileName);
					std.file.write(fileName, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<kml xmlns=\"http://earth.google.com/kml/2.1\">\n");
					std.file.append(fileName, "<Document>\n<Folder>\n");
				}
				
				//dump this Placemark in the kml file
				std.file.append(fileName, placemark.toString());
				std.file.append(fileName, "\n");
			}
		}
	}

	//add footer, finish off each output file
	foreach(kmlFile; outputFiles)
	{
		writeln("Finishing ", kmlFile);
		std.file.append(kmlFile, "</Folder>\n</Document>\n");
		std.file.append(kmlFile, "</kml>");
	}
	sw.stop();

	writefln("Combined Placemarks from %d input files\n", inputFiles.length);
	writefln("Wrote %d route files in %s\n", outputFiles.length, sw.peek().toString());
}

//See if this route is one we've already started processing.
pure @safe bool isNewRoute(char[][] haystack, string needle)
{
	return !canFind!((char[] a, string b) => a.endsWith(b))(haystack, needle);
}