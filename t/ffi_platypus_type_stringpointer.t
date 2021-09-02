use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->load_custom_type('::StringPointer' => 'string_p');

$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');
$ffi->attach( string_pointer_pointer_get => ['string_p'] => 'string');
$ffi->attach( string_pointer_pointer_set => ['string_p', 'string'] => 'void');
$ffi->attach( pointer_pointer_is_null => ['string_p'] => 'int');
$ffi->attach( pointer_is_null => ['string_p'] => 'int');
$ffi->attach( string_pointer_pointer_return => ['string'] => 'string_p');
$ffi->attach( pointer_null => [] => 'string_p');

subtest 'arg pass in' => sub {
  is string_pointer_pointer_get(\"hello there"), "hello there", "not null";
  is pointer_pointer_is_null(\undef), 1, "\\undef is null";
  is pointer_is_null(undef), 1, "undef is null";
};

subtest 'arg pass out' => sub {
  my $string = '';
  string_pointer_pointer_set(\$string, "hi there");
  is $string, "hi there", "not null string = $string";

  my $string2;
  string_pointer_pointer_set(\$string2, "and another");
  is $string2, "and another", "not null string = $string2";

};

subtest 'return value' => sub {
  my $string = "once more onto";

  is string_pointer_pointer_return($string), \"once more onto", "not null string = $string";
  is string_pointer_pointer_return(undef), \undef, "\\null";
  my $value = pointer_null();
  is $value, undef, "null";

};

done_testing;
