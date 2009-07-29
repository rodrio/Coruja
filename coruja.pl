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
# call writeLog("logfile", "string");
sub writeLog{
  my $logfile = $_[0];
  my $str = $_[1];
  my $garbage = $_[2];
  
  open (LOG, ">>$logfile") or die "----> Could not open $logfile $!\n";
  print LOG $str;
  close LOG;
}

# Function that uses the resources prepared in rssVerify() to parse $site, searching for $word
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
  my $enditemtag = "</item>";
  
  # Other variables
  my $interesting;
  my $data;
  
#  print "Starting parse on '$site' for the pattern '$word'...\n"; #DEBUG
  
  # $data receives the GET content to be parsed
  $data = $resource->content;
  
  # Extracting items from $data
  if(index($data, $word)>0){
#    print "Pattern '$word' found on feed '$site'!\n"; #DEBUG
    writeLog("log.txt","--->Pattern Found: $word<---\n");
    
    # Will write $interesting on LOG if it is on the correct item
    # Then removes from $data what has already been verified
    while(index($data, $word)>0){
#      print "Item parsing loop reached...\n"; #DEBUG
      $pos1 = index($data, $itemtag);
      $pos2 = index($data, $word);
      $pos3 = index($data, $enditemtag);
      if($pos3>$pos2 and $pos2>$pos1){
#        print "Item delimiters found. Extracting interesting content...\n"; #DEBUG
        $interesting = substr($data, $pos1, $pos3-$pos1+charCount($enditemtag));
        writeLog("log.txt","$interesting\n");
        writeLog("log.txt","\n");
#        print "Interesting content written into log...\n"; #DEBUG
      }
      
#      print "Removing already verified content\n"; #DEBUG
      $data = substr($data, $pos3+charCount($enditemtag));
    }
  }
}


# Function that performs the HTTP Request to check each link on feedlist
# and combines them with each word on wordlist
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
  my $versiontag = "<rss version";
  my $titletag = "<title";
  
  # Other variables
  my $version;
  my $title;
  
  
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
      $title = substr($title, index($title, $titletag));
      $title = substr($title, index($title, $titletag), index($title, ">")-index($title, $titletag)+1);
    }else{
      $title = "No title tag ($titletag>) found.";
    }
    # Extracting feed version
    $version = $resource->content;
    if (index($version, $versiontag)>0){
      $version = substr($version, index($version, $versiontag));
      $version = substr($version, index($version, $versiontag), index($version, ">")-index($version, $versiontag)+1);
    }else{
      $version = "No version tag ($versiontag>) found.";
    }
    
    # Header of logfile, foreach feed
    writeLog("log.txt","==============================");
    writeLog("log.txt","\n");
    writeLog("log.txt","RSS Feed: $site\n");
    writeLog("log.txt","RSS Title: $title\n");
    writeLog("log.txt","RSS Version: $version\n");
    writeLog("log.txt","\n");
    
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
  }
}



print "Running... Please be sure you have internet connectivity!\n";
rssVerify("links", "patterns");

  # Verifying written log
  open(DATA, "log.txt") || die("ERROR: No log.txt generated! Please run again...\n");
  close(DATA);

print "Info succesfully attached to log!\n";