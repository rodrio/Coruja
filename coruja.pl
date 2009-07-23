#!/usr/bin/perl -w


use strict;
use LWP::UserAgent;

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

# Function that performs the HTTP request and mines the result
# It returns everything in between the specified tags
# EX: rss_verify("http://rss.com/rss.xml", "<title>","</title>") returns everything between <title> and </title>

sub rssVerify{
  # Create a user agent object
  my $agent = LWP::UserAgent->new;
  $agent->agent("Dobermann v0.1");

  # Indexing the RSS sites
  my $sitelist = $_[0];
  open(DATA, $sitelist) || die("Could not open file $sitelist!\n");
  my @rawdata = <DATA>;
  close(DATA);
  my $site;

  # Indexing the words to search
  my $wordlist = $_[1];
  open(DATA, $wordlist) || die("Could not open file $wordlist!\n");
  my @search = <DATA>;
  close(DATA);
  my $word;

  foreach $site (@rawdata){
    $site = trim($site);
    # Variables to handle text mining
    my $pos1;
    my $pos2;
    my $pos3;
    my $id;
    # Variables to handle XML tags
    my $idtag = "<title>";
    my $endidtag = "</title>";
    my $itemtag = "<item>";
    my $enditemtag = "</item>";

    # Other variables
    my $interesting="";
    my $data;

    # Creating the request and passing to the agent to get a response back
    my $request = HTTP::Request->new(GET => $site);
    my $resource = $agent->request($request);

    # Operating...
    #
    # First, parse the RSS Feed and Title for each pattern found
    if($resource->is_success){
      foreach $word (@search){
        $word = trim($word);
        print "Current RSS Feed for search: $site\n"; #DEBUG
        print "Current pattern for search: $word\n"; #DEBUG
        if(index($resource->content, $word)>0){
          print "Pattern $word found!\n"; #DEBUG
          $pos1 = index($resource->content, $idtag);
          $pos2 = index($resource->content, $endidtag);
          $id = substr($resource->content, $pos1+charCount($idtag), $pos2-$pos1-charCount($idtag));

          print "Writing on log...\nRSS Feed: $site\nTitle: $id\nPattern Found: $word\n\nLog written...\n"; #DEBUG
          open (LOG, ">>log.txt") or die "Could not open file $!\n";
          print LOG "\n\n-----------------------------------------------\n";
          print LOG "RSS Feed: $site\nTitle: $id\nPattern Found: $word\n\n";
          close LOG;

          # Now $data receives the GET content to be parsed
          $data = $resource->content;

          # Check while there is a $word pattern found
          # Each time, writes $interesting on LOG if it is on the correct item
          # Each time removes from $data what has already been verified
          while(index($data, $word)>0){
            print "while reached\n"; #DEBUG
            $pos1 = index($data, $itemtag);
            $pos2 = index($data, $word);
            $pos3 = index($data, $enditemtag);
            if($pos3>$pos2 and $pos2>$pos1){
              print "interesting reached\n"; #DEBUG
              $interesting = substr($data, $pos1, $pos3-$pos1+charCount($enditemtag));
              open (LOG, ">>log.txt") or die "Could not open file $!\n";
              print LOG "$interesting\n";
              close LOG;
              print "Log file written with interesting content.\n"; #DEBUG
            }
            print "removing verified content\n"; #DEBUG
            $data = substr($data, $pos3+charCount($enditemtag));
          }
        }
      }
      
      print "File log.txt generated.\n";
    }else{
      print "ERROR: Request not successful.";
    }
  }
}



rssVerify("links", "patterns");