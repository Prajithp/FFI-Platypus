use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::TypeParser;
use FFI::CheckLib;

BEGIN {
  local $SIG{__WARN__} = sub {
    my $message = shift;
    return note $message if $message =~ /hides Math\/LongDouble\.pm/;
    warn $message;
  };

  skip_all 'test requires support for long double'
    unless FFI::Platypus::TypeParser->have_type('longdouble');
  skip_all 'test requires Devel::Hide 0.0010'
    unless eval q{ use Devel::Hide 0.0010 qw( Math::LongDouble ); 1; };
}

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', libpath => 't/ffi');

subtest 'Math::LongDouble is loaded when needed for return type' => sub {
  is($INC{'Math/LongDouble.pm'}, undef, 'not pre-loaded');
  $ffi->function( longdouble_add => ['longdouble','longdouble'] => 'longdouble' );
  my $loaded = Math::LongDouble->can("new");
  ok !$loaded;
};

$ffi->type('longdouble*' => 'longdouble_p');
$ffi->type('longdouble[3]' => 'longdouble_a3');
$ffi->type('longdouble[]'  => 'longdouble_a');
$ffi->attach( [longdouble_add => 'add'] => ['longdouble','longdouble'] => 'longdouble');
$ffi->attach( longdouble_pointer_test => ['longdouble_p', 'longdouble_p'] => 'int');
$ffi->attach( longdouble_array_test => ['longdouble_a', 'int'] => 'int');
$ffi->attach( [longdouble_array_test => 'longdouble_array_test3'] => ['longdouble_a3', 'int'] => 'int');
$ffi->attach( longdouble_array_return_test => [] => 'longdouble_a3');
$ffi->attach( pointer_is_null => ['longdouble_p'] => 'int');
$ffi->attach( longdouble_pointer_return_test => ['longdouble'] => 'longdouble_p');
$ffi->attach( pointer_null => [] => 'longdouble_p');

subtest 'without Math::LongDouble' => sub {
  skip_all 'test requires Math::LongDouble'
    if eval q{ use Math::LongDouble; 1 };

  subtest 'scalar' => sub {
    is add(1.5, 2.5), 4.0, "add(1.5,2.5) = 4";
  };

  subtest 'pointer' => sub {
    my $x = 1.5;
    my $y = 2.5;
    ok longdouble_pointer_test(\$x, \$y);
    ok $x == 4.0;
    ok $y == 8.0;
    ok pointer_is_null(undef);

    my $c = longdouble_pointer_return_test(1.5);
    ok $$c == 1.5;
  };

  subtest 'array fixed' => sub {
    my $list = [ qw( 25.0 25.0 50.0 )];

    ok longdouble_array_test3($list, 3);
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == 1.0;
    ok $list->[1] == 2.0;
    ok $list->[2] == 3.0;
  };

  subtest 'array var' => sub {
    my $list = [ qw( 25.0 25.0 50.0 )];

    ok longdouble_array_test($list, 3);
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == 1.0;
    ok $list->[1] == 2.0;
    ok $list->[2] == 3.0;
  };

  subtest 'array return' => sub {
    my $list = longdouble_array_return_test();
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == 1.0;
    ok $list->[1] == 2.0;
    ok $list->[2] == 3.0;
  };
};

done_testing;
