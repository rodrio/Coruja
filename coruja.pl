#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use XML::RSS;
use List::MoreUtils qw(uniq);
use App::Rad;

my $CORUJA_VERSION = 0.3;
my $CORUJA_DEV = "-pre1"; #ON launch of a stable version, set this as "".
my $CORUJA_URL = "http://www.gris.dcc.ufrj.br";

# Set-up for App::Rad
sub setup{

	my $app = shift;

	# We really don't have subcommands :P
	$app->register_commands(qw(xml html));
	
}

# Create a global user agent object
my $agent = LWP::UserAgent->new;
$agent->agent("Coruja v" . $CORUJA_VERSION . $CORUJA_DEV);

# Start XML Logfile
my $coruja = new XML::RSS(version => '1.0');
$coruja->channel(
	title => "Coruja Feed Parser v" . $CORUJA_VERSION . $CORUJA_DEV,
	link => $CORUJA_URL,
	description => "We watch it for you! ;)"
);

my $rss_source = new XML::RSS;
my $DEBUG = 0;

#Files:
my $patfile = "patterns.txt";
my $linksfile = "links.txt";
my $xmloutput = "coruja.xml";
my $htmloutput = "coruja.html";

# Mode of operation:
# 0 = xml
# 1 = html
my $opmode = 0;

# HTML output buffer:
my $htmloutbuf;

# First... let's build the initial html struct...
$htmloutbuf = "<html>\n";
$htmloutbuf .= "<head>\n";
$htmloutbuf .= "<title>Coruja Feed Parser Results - We watch it for you! ;)</title>\n";
$htmloutbuf .= "<META http-equiv=Content-Type content=\"text/html; charset=ISO-8859-1\">\n";
$htmloutbuf .= "</HEAD>\n\n";
$htmloutbuf .= "<body>\n";

# Function that trims words
# call trim("word");
sub trim{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Function that writes the output into a file
# call writeLog("logfile", "String to write");

# Function that searches $rss_source for a word/pattern
# Call feedParse("pattern")
sub feedParse{
	# Receiving resources
	my $word = shift;
	my $title;
	my $description;

	$word = lc($word);
	# Let's search in each entry of rss...
	foreach my $rss_entry (@{$rss_source->{'items'}}) {

		$title = lc($rss_entry->{'title'});
		$description = lc($rss_entry->{'description'});
		# ... and if we find the word in title ...
		unless (index($title, $word) == -1 and index($description, $word) == -1)
		{
			print "Found $word at $title\n" if $DEBUG == 1;
			# ... then we put it on our final feed.
			push @{$coruja->{'items'}}, $rss_entry;


			if($opmode == 1)
			{
				# ... now, we get our item feed and put it there ...
				$htmloutbuf .= "      <ul>\n";
				$htmloutbuf .= "        <li><font size=\"4\"><b>$rss_entry->{'title'}</b></font></li>\n";
				$htmloutbuf .= "        <b>Description:</b>$rss_entry->{'description'}<br>\n" if ($rss_entry->{'description'});
				$htmloutbuf .= "        <b>Link:</b><a href=\"$rss_entry->{'link'}\">$rss_entry->{'link'}</a><br>\n";
				$htmloutbuf .= "      </ul>\n";
			}
		}
	}
}


# Function that performs the HTTP Request to check each link on feedlist
# and combines them with each word on wordlist
# Call rssVerify("feedlist","wordlist")
sub rssVerify{
	my $request;
	my $resource;

	# List files (names)
	my $sitelistfilename = shift;
	my $wordlistfilename = shift;

	# Feed Attrs
	my $feedtitle;
	my $feeddescription;
	my $feedlink;
	my $feedpubdate;
	
	# Get RSS list to check.
	open(DATA, $sitelistfilename) || die("Could not open file $sitelistfilename!\n");
	my @links = <DATA>;
	close(DATA);
  
	# Get wordlist to check.
	open(DATA, $wordlistfilename) || die("Could not open file $wordlistfilename!\n");
	my @search = <DATA>;
	close(DATA);

	if($opmode == 1)
	{
		$htmloutbuf .= "<table width=\"600\" border=\"1\">\n";
		$htmloutbuf .= "  <tr>\n";
		$htmloutbuf .= "    <td>\n";
	}



	print "Parsing feed list...\n" if $DEBUG == 1;
  
	# Let's check out feed then...
	foreach my $site (@links){
		$site = trim($site);
    
		# Filter empty and commented (#) lines
		next if $site =~ /^#/;
		next if $site =~ /^\n/;
		next if $site =~ /^\r/;
		next if $site eq "";
    
		$request = HTTP::Request->new(GET => $site);
		$resource = $agent->request($request);

		# Parsing do XML
		$rss_source->parse($resource->content());

		# Extracting feed title
		$feedtitle = $rss_source->channel('title');
		$feeddescription = $rss_source->channel('description');
		$feedlink = $rss_source->channel('link');
		$feedpubdate = $rss_source->channel('pubdate');
		
		print "Parsing $feedtitle ($site)...\n";
		
		if($opmode == 1)
		{
			# Building HTML structure
			$htmloutbuf .= "      <font size=\"5\">$feedtitle</font><br>\n";
			$htmloutbuf .= "      <font size=\"4\">$feeddescription</font><br>\n";
			# TODO: Fetch pubdate of each feed
			#$htmloutbuf .= "      <font size=\"4\">$feedpubdate</font><br>\n";
			$htmloutbuf .= "      <font size=\"2\"><a href=\"$feedlink\">$feedlink</a></font><br>\n";
			$htmloutbuf .= "      <font size=\"2\"><a href=\"$site\">[original feed]</a></font><br>\n";
			$htmloutbuf .= "      <br><br>\n";
		}
		
		#Let's see if we find our work there ;)
		foreach my $word (@search){
			$word = trim($word);
      
			# Filter empty and commented (#) lines
			next if $word =~ /^#/;
			next if $word =~ /^\n/;
			next if $word =~ /^\r/;
			next if $word eq "";
      
			feedParse($word);
		}
	}

	# And before saving, we check to see if we didn't included duplicade entries:
	@{$coruja->{'items'}} = uniq @{$coruja->{'items'}};


	if($opmode == 1) #html
	{
		$htmloutbuf .= "	</td>\n";
		$htmloutbuf .= "  </tr>\n";
		$htmloutbuf .= "</table>\n";
		$htmloutbuf .= "</body>\n</html>\n";

		my $DATA;
		open($DATA, '>', $htmloutput);
		print $DATA $htmloutbuf;
		close($DATA);

		open($DATA, $htmloutput) || die("ERROR: No $htmloutput generated! Please run again...\n");
		close($DATA);
	}

	# Closing and saving XML file
	$coruja->save($xmloutput);
	
	my $DATA;
	open($DATA, $xmloutput) || die("ERROR: No $xmloutput generated! Please run again...\n");
	close($DATA);
}

sub main{
	print "Starting Coruja v" . $CORUJA_VERSION . $CORUJA_DEV . "... Please be sure you have internet connectivity!\n";
	rssVerify($linksfile, $patfile);
	print "Info succesfully attached to log!\n";
	return undef;
}

sub xml
:Help(Generate only xml file as output. [DEFAULT]
			You can pass the following options to Coruja in xml mode:
      			--patterns=patternsfile.txt - Read patterns from patternsfile.txt
			--feeds=linksfile.txt - Read feeds link from linksfile.txt
			--xmlout=coruja.xml - Output the xml to coruja.xml){
	
	my $c = shift;

	if($c->options->{'help'} or $c->options->{'h'})
	{
		print   "\n" .
			"The xml output model is the Coruja's default operation mode.\n\n" .
			"At xml mode, Coruja will parse all the feeds, looking for defined words at all entry's title.\n" .
			"Then it will create a new RSS valid file, with the result from the search.\n\n." .
			"Coruja at xml options accept these options:\n\n" .
			"--patterns=patternsfile.txt\n" .
			"\tThis option tell Coruja to look at words in the patternsfile.txt.\n" .
			"--feeds=linksfile.txt\n" .
			"\tThis option tell Coruja to parse the feeds at specified URLs.\n" .
			"--xmlout=coruja.xml\n" .
			"\tThis option tell Coruja to output the final feed to coruja.xml.\n" .
			"\n" .
			"To know more about Coruja, go to GRIS website: $CORUJA_URL\n\n";

		exit;
	}
	
	
	main();

	return undef;
}

sub html
:Help(Generate a xml and a html file as output. Good to preview the final feed.
      			You can pass the following options to Coruja in html mode:
      			--patterns=patternsfile.txt - Read patterns from patternsfile.txt
			--feeds=linksfile.txt - Read feeds link from linksfile.txt
			--htmlout=coruja.html - Output the html to coruja.html
			--xmlout=coruja.xml - Output the xml to coruja.xml){
	my $c = shift;

	if($c->options->{'help'} or $c->options->{'h'})
	{
		print   "\n" .
		"At html mode, Coruja will parse all the feeds, looking for defined words at all entry's title.\n" .
		"Then it will create a new RSS valid file, with the result from the search AND generate an html file.\n" .
		"The purpose of this html file is just for a quick preview and see what items Coruja got, without the need to go through the xml file.\n\n".
		"Coruja at html options accept these options:\n\n" .
		"--patterns=patternsfile.txt\n" .
		"\tThis option tell Coruja to look at words in the patternsfile.txt.\n" .
		"--feeds=linksfile.txt\n" .
		"\tThis option tell Coruja to parse the feeds at specified URLs.\n" .
		"--xmlout=coruja.xml\n" .
		"\tThis option tell Coruja to output the final feed to coruja.xml.\n" .
		"--htmlout=coruja.html\n" .
		"\tThis option tell Coruja to output the html file to coruja.html.\n" .
		"\n" .
		"To know more about Coruja, go to GRIS website: $CORUJA_URL\n\n";

		exit;
	}

	$opmode = 1;
	main();

	return undef;
}

# Let's check for options \o/
sub pre_process{
	my $c = shift;

	if($c->options->{'version'} or $c->options->{'V'})
	{
		print   "Coruja v" . $CORUJA_VERSION . $CORUJA_DEV . "\n".
			"Visit $CORUJA_URL for more information about Coruja and other projects developed by GRIS.\n\n";

		exit;
	}

	$patfile = $c->options->{'patterns'} if $c->options->{'patterns'};
	$linksfile = $c->options->{'feeds'} if $c->options->{'feeds'};
	$xmloutput = $c->options->{'xmlout'} if $c->options->{'xmlout'};
	$htmloutput = $c->options->{'htmlout'} if $c->options->{'htmlout'};
}


sub default{
	my $c = shift;


	if($c->options->{'help'} or $c->options->{'h'})
	{
		print   "\n".
			"For general help: '$0 help'\n".
			"For specific module help: '$0 [xml|html] --help'\n\n";
		exit;
	}

	main(); # Execute xml mode as default
	return undef;
}

App::Rad->run();

