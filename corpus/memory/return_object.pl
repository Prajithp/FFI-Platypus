use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use Math::Complex;
use Test::LeakTrace qw( no_leaks_ok );

my @types = map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 );

{
  package Foo;

  sub new
  {
    my($class, $arg) = @_;
    bless \$arg, $class;
  }
}

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new( api => 1 );
    my $f = $ffi->function(0 => [] => "object(Foo,$type)" );
    no_leaks_ok { $f->call };
  }
}

subtest 'opaque' => sub {
  my $ffi    = FFI::Platypus->new( api => 1, lib => [undef] );
  my $malloc = $ffi->function( malloc => [ 'size_t' ] => 'opaque' );
  my $free   = $ffi->function( free => [ 'opaque' ] => 'void' );
  my $ptr    = $malloc->call(200);
  my $f      = $ffi->function(0 => [ 'object(Foo)' ] => 'object(Foo)' );

  my $foo1 = Foo->new($ptr);

  no_leaks_ok { $f->call($foo1) };
  $free->call($ptr);

  my $foo2 = Foo->new(undef);
  no_leaks_ok { $f->call($foo2) };
};

done_testing;
