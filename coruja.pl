#!/usr/bin/perl -w

use strict;
use LWP::UserAgent;

# Create a global user agent object
my $agent = LWP::UserAgent->new;
$agent->agent("Dobermann v0.1");

# Global variables, used in multiple functions
my $site;
my $word;
my $request;
my $resource;

# Function that trims words
# call trim("word");
sub trim{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Function that counts how many chars a word have
# call charCount("word");
sub charCount{
  my $str = $_[0];
  my $garbage = $_[1];
  my $num;
  $num++ while $str =~ s/.//;
  return $num;
}

# Function that writes the output into a file
# call writeLog("logfile", "String to write");
sub writeLog{
  my $logfile = $_[0];
  my $str = $_[1];
  my $garbage = $_[2];
  
  open (LOG, ">>$logfile") or die "----> Could not open $logfile $!\n";
  print LOG $str;
  close LOG;
}

# Function that uses the resources prepared in rssVerify() to parse $site, searching for $word
# Call feedParse("url","pattern",$resource)
sub feedParse{
  # Receiving resources
  $site = $_[0];
  $word = $_[1];
  $resource = $_[2];
  my $garbage = $_[3];
  
  # Variables to handle text mining
  my $pos1;
  my $pos2;
  my $pos3;
  my $id;
  my $posaux;
  
  # Variables to handle XML tags
  my $itemtag = "<item";
  my $itemtagend = "</item>";
  
  # Other variables
  my $interesting;
  my $data;
  
#  print "Starting parse on '$site' for the pattern '$word'...\n"; #DEBUG
  
  # $data receives the GET content to be parsed
  $data = $resource->content;
  
  # Extracting items from $data
  if(index($data, $word)>0){
#    print "Pattern '$word' found on feed '$site'!\n"; #DEBUG
    #writeLog("log.xml","--->Pattern $word found!!!");
    
    # Will write $interesting on LOG if it is on the correct item
    # Then removes from $data what has already been verified
    while(index($data, $word)>0){
#      print "Item parsing loop reached...\n"; #DEBUG
      $pos1 = index($data, $itemtag);
      $pos2 = index($data, $word);
      $pos3 = index($data, $itemtagend);
      if($pos3>$pos2 and $pos2>$pos1){
#        print "Item delimiters found. Extracting interesting content...\n"; #DEBUG
        $interesting = substr($data, $pos1, $pos3-$pos1+charCount($itemtagend));
        writeLog("log.xml","$interesting\n");
        writeLog("log.html","$interesting\n");
        #writeLog("log.xml","\n");
#        print "Interesting content written into log...\n"; #DEBUG
      }
      
#      print "Removing already verified content\n"; #DEBUG
      $data = substr($data, $pos3+charCount($itemtagend));
    }
  }
}


# Function that performs the HTTP Request to check each link on feedlist
# and combines them with each word on wordlist
# Call rssVerify("feedlist","wordlist")
sub rssVerify{
  # Indexing the RSS sites
  my $sitelist = $_[0];
  open(DATA, $sitelist) || die("Could not open file $sitelist!\n");
  my @links = <DATA>;
  close(DATA);
  
  # Indexing the words to search
  my $wordlist = $_[1];
  open(DATA, $wordlist) || die("Could not open file $wordlist!\n");
  my @search = <DATA>;
  close(DATA);
  
  # Variables to handle XML tags
  my $versiontag = "<rss version=\"";
  my $titletag = "<title>";
  my $titletagend = "</title>";
  
  # Other variables
  my $version;
  my $title;
  my $datetime = localtime();
  
  # Header of XML logfile
  writeLog("log.xml","<?xml version=\"1.0\"?>\n");
  writeLog("log.xml","<rss version=\"2.0\">\n");
  writeLog("log.xml","\n");
  # Header of HTML logfile
  writeLog("log.html","<HTML><HEAD>\n");
  writeLog("log.html","<title>Coruja Feed Parser Results</title>\n");
  writeLog("log.html","<META http-equiv=Content-Type content=\"text/html; charset=ISO-8859-1\">\n");
  writeLog("log.html","</HEAD>\n");
  writeLog("log.html","\n<body>\n");
  
  # Foreach $site, foreach $word...
  foreach $site (@links){
#    print "Parsing feed list...\n"; #DEBUG
    $site = trim($site);
    
    # Filter empty and commented (#) lines
    next if $site =~ /^#/;
    next if $site =~ /^\n/;
    next if $site =~ /^\r/;
    next if $site eq "";
    
    $request = HTTP::Request->new(GET => $site);
    $resource = $agent->request($request);
    
    # Extracting feed title
    $title = $resource->content;
    if (index($title, $titletag)>0){
      $title = substr($title, index($title, $titletag)+charCount($titletag), index($title, $titletagend)-index($title, $titletag)-charCount($titletag));
    }else{
      $title = "No title tag ($titletag>) found.";
    }
    # Extracting feed version
    $version = $resource->content;
    if (index($version, $versiontag)>0){
      $version = substr($version, index($version, "version=\"")+charCount("version=\""));
      $version = substr($version, 0, index($version, "\""));
    }else{
      $version = "No version tag ($versiontag\">) found.";
    }
    
    # Header on XML logfile of each feed
	writeLog("log.xml","<channel>\n");
    writeLog("log.xml","  <link>$site</link>\n");
    writeLog("log.xml","  <title>$title</title>\n");
	# A coleta da versao do RSS ta dando erro ainda. Precisa ser aprimorada.
	#writeLog("log.xml","  <!--<description>RSS Version of this Feed: $version</description>-->\n");
	writeLog("log.xml","  <description>by Coruja Feed Parser</description>\n");
    writeLog("log.xml","  <pubDate>$datetime</pubDate>\n");

    # Header on HTML logfile of each feed
	writeLog("log.html","<table border=\"1\" width=\"600\"><tr><td>\n");
    writeLog("log.html","  <h1>$title</h1>\n");
	# A coleta da versao do RSS ta dando erro ainda. Precisa ser aprimorada.
	writeLog("log.html","  <h2>RSS Version of this Feed: $version</h2>\n");
    writeLog("log.html","  <h2>$datetime</h2>\n");
	writeLog("log.html","  <h3>by Coruja Feed Parser</h3>\n");
    writeLog("log.html","  <a href=\"$site\">ORIGINAL RSS FEED LINK</a>\n");
    
    foreach $word (@search){
#      print "Parsing word list...\n"; #DEBUG
      $word = trim($word);
      
      # Filter empty and commented (#) lines
      next if $word =~ /^#/;
      next if $word =~ /^\n/;
      next if $word =~ /^\r/;
      next if $word eq "";
      
      feedParse($site, $word, $resource);
    }

	# Closing XML Logfile feed header
    writeLog("log.xml","</channel>\n");
    writeLog("log.xml","\n");
	# Closing HTML Logfile feed header
    writeLog("log.html","</td></tr></table>\n");
    writeLog("log.html","\n");
  }
  # Closing XML Logfile
  writeLog("log.xml","</rss>\n");
  writeLog("log.xml","\n");
  # Closing HTML Logfile
  writeLog("log.html","</body></html>\n");
  writeLog("log.html","\n");
}



print "Running... Please be sure you have internet connectivity!\n";
rssVerify("links", "patterns");

# Verifying written log
open(DATA, "log.xml") || die("ERROR: No log.xml generated! Please run again...\n");
my @log = <DATA>;
close(DATA);
my $line;

# Converting log to HTML...
#foreach $line (@log){
#  $line =~ s/<\?xml version\=\"1\.0\"\?>/<html>/;
#  $line =~ s/<rss version\=\"2\.0\">/<body>/;
#  $line =~ s/<\/rss>/<\/body>/;
#  $line =~ s/<channel>/<table><tr><td border=\"1\">/;
#  $line =~ s/<\/channel>/<\/td><\/tr><\/table>/;
#  $line =~ s/\<link\>/\<a\ href\=\"/;
#  $line =~ s/\<\/link\>/\"\>LINK\<\/a\>/;
#  writeLog("log.html",$line);
#}

print "Info succesfully attached to log!\n";