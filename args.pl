sub my_args
{
  my $i;
  print "My arguments:\n";
  for($i=0;$i<=$#_;$i++){
    print "Argument $i: $_[$i]\n";
  }
  print "\n";
}

my $name = "arg one";
my @names = ('This', 'is', 'an', 'array');

my_args($name);
my_args($name, 123);
my_args(123, 345, @names, $name);
