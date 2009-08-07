#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use XML::RSS;
use List::MoreUtils qw(uniq);
use App::Rad;
use Tk;


#####################
# Version variables #
#####################
my $CORUJA_VERSION = 0.3;
my $CORUJA_DEV = "-rc2"; #ON launch of a stable version, set this as "".
my $CORUJA_URL = "http://www.gris.dcc.ufrj.br";

####################
# Global Variables #
####################
my $mainwindow; #GUI Mainwindow
my $downleft; #GUI Frame that demands realtime updating
my $downright; #GUI Frame that demands realtime updating
my $rss_source = new XML::RSS;
my $DEBUG = 0;
# GUI Output choosing options
my @outputmode = ('XML','HTML');
# Create a global user agent object
my $agent = LWP::UserAgent->new;
$agent->agent("Coruja v" . $CORUJA_VERSION . $CORUJA_DEV);
# HTML output buffer:
my $htmloutbuf;
$htmloutbuf = "<html>\n";
$htmloutbuf .= "<head>\n";
$htmloutbuf .= "<title>Coruja Feed Parser Results - We watch it for you! ;)</title>\n";
$htmloutbuf .= "<META http-equiv=Content-Type content=\"text/html; charset=ISO-8859-1\">\n";
$htmloutbuf .= "</HEAD>\n\n";
$htmloutbuf .= "<body>\n";
# XML output buffer
my $xmloutbuf = new XML::RSS(version => '1.0');
$xmloutbuf->channel(
	title => "Coruja Feed Parser v" . $CORUJA_VERSION . $CORUJA_DEV,
	link => $CORUJA_URL,
	description => "We watch it for you! ;)"
);
#Hash Vectors:
my $config = {
	MODE => 'GUI',
	FEEDSFILENAME => 'links.txt',
	PATTERNSFILENAME => 'patterns.txt',
	};
my $output = {
	MODE => '',
	FILENAME => 'coruja',
	};

###############
# subroutines #
###############
sub trim{
# Function that trims words
# call trim("word");
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub feedParse{
# Function that searches $rss_source for a word/pattern
# Call feedParse("pattern")
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
		unless (index($title, $word) == -1 and index($description, $word) == -1){
			print "Found $word at $title\n" if $DEBUG == 1;
			# ... then we put it on our final feed.
			push @{$xmloutbuf->{'items'}}, $rss_entry;
			if($output->{MODE} eq 'HTML'){
				# Highlighting $word
				$title = $rss_entry->{'title'};
				$description = $rss_entry->{'description'};
				$title =~ s/$word/<u>$word<\/u>/i;
				$description =~ s/$word/<u>$word<\/u>/i;
				# ... now, we get our item feed and put it there ...
				$htmloutbuf .= "      <ul>\n";
				$htmloutbuf .= "        <li><font size=\"4\"><b>$title</b></font></li>\n";
				$htmloutbuf .= "        <b>Description:</b>$description<br>\n" if ($rss_entry->{'description'});
				$htmloutbuf .= "        <b>Link:</b><a href=\"$rss_entry->{'link'}\">$rss_entry->{'link'}</a><br>\n";
				$htmloutbuf .= "      </ul>\n";
			}
		}
	}
}

sub corujaStart{
# Function that performs the HTTP Request to check each link on feedlist
# and combines them with each word on wordlist
# Call corujaStart("feedlist","wordlist")
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
	open(DATA, $sitelistfilename) or die("Could not open file $sitelistfilename!\n");
	my @links = <DATA>;
	close(DATA);
  
	# Get wordlist to check.
	open(DATA, $wordlistfilename) or die("Could not open file $wordlistfilename!\n");
	my @search = <DATA>;
	close(DATA);

	if($output->{MODE} eq 'HTML')
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
		# Update status on text widgets on GUI
		# But it is not working yet...
		#$downleft->insert("end", "Parsing $feedtitle ($site)...\n");
		#$mainwindow->update();
		
		if($output->{MODE} eq 'HTML'){
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
      
			# Update status on text widgets on GUI
			# But it is not working yet...
			#$downright->insert("end", "Searching for $word...\n");
			#$mainwindow->update();
			feedParse($word);
		}
	}

	# And before saving, we check to see if we didn't included duplicade entries:
	@{$xmloutbuf->{'items'}} = uniq @{$xmloutbuf->{'items'}};

	# Closing and saving HTML file
	if($output->{MODE} eq 'HTML'){
		$htmloutbuf .= "	</td>\n";
		$htmloutbuf .= "  </tr>\n";
		$htmloutbuf .= "</table>\n";
		$htmloutbuf .= "</body>\n</html>\n";

		my $DATA;
		open($DATA, '>', $output->{FILENAME});
		print $DATA $htmloutbuf;
		close($DATA);

		open($DATA, $output->{FILENAME}) or die("ERROR: No $output->{FILENAME} generated! Please run again...\n");
		close($DATA);
	}

	# Closing and saving XML file
	$xmloutbuf->save($output->{FILENAME}) if $output->{'MODE'} eq 'XML';
	
	my $DATA;
	open($DATA, $output->{FILENAME}) or die("ERROR: No $output->{FILENAME} generated! Please run again...\n");
	close($DATA);
}

#####################
# GUI Configuration #
#####################
MAIN: {
  # Let's create our MainMenu
  $mainwindow = MainWindow->new();
  my $menubar = $mainwindow->Frame()->grid(-row => 0, -column => 0, -columnspan => 3, -sticky => 'nw');
  
  # Now let's create our menus
  my $corujamenu = $menubar->Menubutton(-text => 'Coruja');
  $corujamenu->command( -label   =>  'Load Feeds', -command =>  \&loadFeeds );
  $corujamenu->command( -label   =>  'Load Patterns', -command => \&loadPatterns  );
  $corujamenu->separator();
  $corujamenu->command(-label   => 'Set output filename', -command => \&setOutputFilename );
  $corujamenu->separator();
  $corujamenu->command(-label => 'Exit', -command => sub {exit;} );
  $corujamenu->pack(-side => 'left');
  my $helpmenu = $menubar->Menubutton(-text => 'Help');
  $helpmenu->command( -label   =>  'Help', -command =>  \&displayHelp);
  $helpmenu->command( -label   =>  'About', -command => \&displayAbout);
  $helpmenu->pack(-side => 'left');
  
  # Let's build the frames for our objects
  my $top   = $mainwindow->Frame->grid(-row => 1,
									   -column => 0,
									   -sticky => 'nw',
									   );
  my $upleft   = $mainwindow->Frame->grid(-row => 2,
										-column => 0,
										-sticky => 'w',
										);
  my $upright  = $mainwindow->Frame->grid(-row => 2,
                                        -column => 1,
                                        -sticky => 'w',
										);
  $downleft  = $mainwindow->Frame->grid(-row => 3,
                                        -column => 0,
                                        -sticky => 'w',
										);
  $downright  = $mainwindow->Frame->grid(-row => 3,
                                        -column => 1,
                                        -sticky => 'w',
										);
  my $bottomleft = $mainwindow->Frame->grid(-row => 4,
                                        -column => 0,
                                        -sticky => 'w',
										);
  my $bottomright = $mainwindow->Frame->grid(-row => 4,
                                        -column => 1,
                                        -sticky => 'e',
										);
  my $bottom1   = $mainwindow->Frame->grid(-row => 5,
									   -column => 1,
									   -sticky => 'e',
									   );
  my $bottom2 = $mainwindow->Frame->grid(-row => 6,
                                        -column => 1,
                                        -sticky => 'e',
										);
  
  # Top frame
  $top->Label(-text => 'Choose output file format:')->
                grid(-row => 0, -column => 0,-sticky => 'w');
  $top->Optionmenu(
					-options => \@outputmode,
					-variable => \$output->{MODE},
					-command => \&updateScreen
					)->grid(-row => 0, -column => 1,-sticky => 'w');

  # Up Left Frame
  $upleft->Label(-text => 'Feed list:')->
                grid(-row => 0, -column => 0,-sticky => 'w');
  $upleft->Label(-textvariable => \$config->{FEEDSFILENAME})->
                grid(-row => 0, -column => 1,-sticky => 'w');
  $upleft->Label(-text => 'Pattern list:')->
                grid(-row => 1, -column => 0,-sticky => 'w');
  $upleft->Label(-textvariable => \$config->{PATTERNSFILENAME})->
                grid(-row => 1, -column => 1,-sticky => 'nw');
  
  # Up Right Frame
#  $upright->Label(-text => 'Pattern list:')->
#                grid(-row => 0, -column => 0,-sticky => 'w');
#  $upright->Label(-textvariable => \$config->{PATTERNSFILENAME})->
#                grid(-row => 0, -column => 1,-sticky => 'nw');
  
  # Down Left Frame
#  $downleft->Text(-width => 50,-height => 10,-state => "disabled");
#  $downleft->insert("end", "Type something here..."); # This is not working
#  $downleft->grid(-row => 0, -column => 0,-sticky => 'w');
  
  # Down Right Frame
#  $downright->Text(-width => 50,-height => 10,-state => "disabled");
#  $downright->insert("end", "Type something here..."); # This is not working
#  $downright->grid(-row => 0, -column => 0,-sticky => 'w');
  
  # Bottom Left Frame
	$bottomleft->Label(-text => 'Output File:')->
                grid(-row => 0, -column => 0,-sticky => 'w');
	$bottomleft->Label(-textvariable => \$output->{'FILENAME'})->
                grid(-row => 0, -column => 1,-sticky => 'w');
  
  # Bottom Right Frame
  
  # Bottom 1 Frame (Coruja Image)
  $bottom1->Photo('CORUJA_LOGO',
				-file =>'images/logo_color.gif',
				);
  $bottom1->Label('-image' => 'CORUJA_LOGO')->pack(-anchor => "center");
  
  # Bottom 2 Frame (Operation button)
  $bottom2->Button(-text => 'Watch it for me!',
				  -width => 17,
                  -command => \&GUIexecute)->
                  grid(qw/-row 0 -column 0 -sticky e/);

}

###################
# GUI subroutines #
###################
sub loadFeeds{
	my @types = (["Text Files", ".txt"],["All Files", "*"]);
	$config->{FEEDSFILENAME} = $mainwindow->getOpenFile(-filetypes => \@types);
}

sub loadPatterns{
	my @types = (["Text Files", ".txt"],["All Files", "*"]);
	$config->{PATTERNSFILENAME} = $mainwindow->getOpenFile(-filetypes => \@types);
}

sub setOutputFilename{
	my @types;
	@types = (["HTML Files", ".html"],["All Files", "*"]) if $output->{'MODE'} eq 'HTML';
	@types = (["HTML Files", ".html"],["All Files", "*"]) if $output->{'MODE'} eq 'XML';
	$output->{'FILENAME'} = $mainwindow->getSaveFile(-filetypes => \@types);
#	setOutputExtension();
	updateScreen();
}

sub updateScreen{
	$mainwindow->update();
}

sub displayHelp(){
	my $help = $mainwindow->DialogBox(-title => "Coruja Help",
			     -buttons => ["Thanks!"]);

	$help->Label(-text =>
				"Coruja v$CORUJA_VERSION$CORUJA_DEV\n\n".
				"Visit $CORUJA_URL\nfor more information about Coruja and other projects developed by GRIS.\n\n".
				"---------------------------------------------------------------------------------------------\n".
				"Coruja Feed Parser is a tool that searches RSS Feeds for interesting content. Just specify\n".
				"the feeds you want Coruja to check and the patterns you want Coruja to search.\n".
				"Coruja will generate an output file containing only what is interesting for you.\n\n"
				)->
                grid(-row => 0, -column => 0,-sticky => 'w');

    my $result = $help->Show;
}

sub displayAbout(){
	my $about = $mainwindow->DialogBox(-title => "About Coruja",
			     -buttons => ["Nice!"]);

	$about->Label(-text =>
				"Coruja v$CORUJA_VERSION$CORUJA_DEV\n\n".
				"Visit $CORUJA_URL\nfor more information about Coruja and other projects developed by GRIS.\n\n".
				"---------------------------------------------------------------------------------------------\n".
				"Coruja authors:\n".
				'Rodrigo M. T. Fernandez (rod.rio@gmail.com)'.
				"\n".
				'Bruno C. Buss (bruno.buss@gmail.com)'.
				"\n\n".
				"Coruja Project:\n".
				"It is an OpenSource Project. Just try to keep original authors info in your dist. Thx.\n".
				"Coruja has been developed by GRIS-DCC-UFRJ.\n".
				"www.gris.dcc.ufrj.br\n"
				)->
                grid(-row => 0, -column => 0,-sticky => 'w');

    my $result = $about->Show;
}

sub GUIexecute(){
	corujaStart($config->{FEEDSFILENAME}, $config->{PATTERNSFILENAME});
}

########################
# App::Rad subroutines #
########################
sub setup{
	# Set-up for App::Rad
	# After setting up, App::Rad will run pre_process()
	my $app = shift;
	# We really don't have subcommands :P
	$app->register_commands(qw(gui xml html));
}

sub pre_process{
	# App::Rad internals
	# Checking for options...
	my $c = shift;
	
	# Check if user wants to see version information with -v, -V or --version
	if($c->options->{'version'} or $c->options->{'V'} or $c->options->{'v'}){
		print
			"Coruja v" . $CORUJA_VERSION . $CORUJA_DEV . "\n".
			"Visit $CORUJA_URL for more information about Coruja and other projects developed by GRIS.\n\n";
		exit;
		}
	
	# Only one output mode allowed. Checking...
	if($c->options->{'xmlout'} and $c->options->{'htmlout'}){
		print
			"ERROR: Only one output mode allowed.\n\n".
			"For general help: '$0 help'\n".
			"For specific module help: '$0 [gui|xml|html] --help'\n\n";
		exit;
		}
	# Now, define variables passed as options
	$config->{PATTERNSFILENAME} = $c->options->{'patterns'} if $c->options->{'patterns'};
	$config->{FEEDSFILENAME} = $c->options->{'feeds'} if $c->options->{'feeds'};
	$output->{FILENAME} = $c->options->{'xmlout'} if $c->options->{'xmlout'};
	$output->{FILENAME} = $c->options->{'htmlout'} if $c->options->{'htmlout'};
	$config->{MODE} = 'GUI'; #Execute GUI mode as default
}

sub default{
	# App::Rad internals
	# If no App::Rad mode is defined on terminal command, run default()
	my $c = shift;

	# Check if user is looking for help with -h or --help
	if($c->options->{'help'} or $c->options->{'h'}){
		print
			"\n".
			"For general help: '$0 help'\n".
			"For specific module help: '$0 [gui|xml|html] --help'\n\n";
		exit;
		}

	main(); 
	return undef;
}

sub gui
:Help(Start Coruja Graphic User Interface mode. [DEFAULT]
			No options are accepted in Coruja GUI mode!){
	my $c = shift;

	if($c->options->{'help'} or $c->options->{'h'}){
		print
			"\n" .
			"The GUI operation mode is the Coruja's default operation mode.\n\n" .
			"At GUI operation mode, you will be able to use the graphic interface to control Coruja's operation.\n" .
			"\n" .
			"To know more about Coruja, go to GRIS website: $CORUJA_URL\n\n";
		exit;
		}

	$config->{MODE} = 'GUI'; #Execute GUI mode as default
	main();
	return undef;
}

sub xml
:Help(Generate only XML file as output.
			You can pass the following options to Coruja in XML mode:
      		--patterns=patternsfile.txt - Read patterns from patternsfile.txt
			--feeds=linksfile.txt - Read feeds link from linksfile.txt
			--xmlout=coruja.xml - Output the XML to coruja.xml){
	
	my $c = shift;

	if($c->options->{'help'} or $c->options->{'h'})
	{
		print   "\n" .
			"At XML mode, Coruja will parse all the feeds, looking for defined words at all entry's title.\n" .
			"Then it will create a new RSS valid file, with the result from the search.\n\n." .
			"Coruja at XML mode accept these options:\n\n" .
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
	
	$output->{MODE} = 'XML';
	$config->{MODE} = 'XML';
	main();

	return undef;
}

sub html
:Help(Generate a HTML file as output. Good to preview the final feed.
      			You can pass the following options to Coruja in HTML mode:
      		--patterns=patternsfile.txt - Read patterns from patternsfile.txt
			--feeds=linksfile.txt - Read feeds link from linksfile.txt
			--htmlout=coruja.html - Output the html to coruja.html){
	my $c = shift;

	if($c->options->{'help'} or $c->options->{'h'})
	{
		print   "\n" .
		"At html mode, Coruja will parse all the feeds, looking for defined words at all entry's title and description.\n" .
		"Then it will create a new HTML file, with the result from the search.\n" .
		"The purpose of this HTML file is just for a quick preview and see what items Coruja got, without the need to go through the XML file.\n\n".
		"Coruja at HTML options accept these options:\n\n" .
		"--patterns=patternsfile.txt\n" .
		"\tThis option tell Coruja to look at words in the patternsfile.txt.\n" .
		"--feeds=linksfile.txt\n" .
		"\tThis option tell Coruja to parse the feeds at specified URLs.\n" .
		"--htmlout=coruja.html\n" .
		"\tThis option tell Coruja to output the html file to coruja.html.\n" .
		"\n" .
		"To know more about Coruja, go to GRIS website: $CORUJA_URL\n\n";

		exit;
	}
	
	$output->{MODE} = 'HTML';
	$config->{MODE} = 'HTML';
	main();

	return undef;
}

###################
# Starting Coruja #
###################
sub main{
	print "Starting Coruja v$CORUJA_VERSION$CORUJA_DEV in $config->{MODE} mode... Please be sure you have internet connectivity!\n";
	corujaStart($config->{FEEDSFILENAME}, $config->{PATTERNSFILENAME}) if $config->{'MODE'} ne 'GUI';
	MainLoop() if $config->{'MODE'} eq 'GUI';
	print "Coruja has ended checking your feeds!\n";
	print "Enjoy!\n";
	return undef;
}

# OK, now we're fine. Start the program! :P
App::Rad->run();

