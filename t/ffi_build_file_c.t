use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build::File::C;
use FFI::Build;
use Capture::Tiny qw( capture_merged );

subtest 'basic' => sub {

  my $file = FFI::Build::File::C->new(['corpus','ffi_build_file_c','basic.c']);

  isa_ok $file, 'FFI::Build::File::C';
  isa_ok $file, 'FFI::Build::File::Base';
  is($file->default_suffix, '.c');
  is($file->default_encoding, ':utf8');

};

subtest 'compile' => sub {

  my $file = FFI::Build::File::C->new([qw( corpus ffi_build_file_c foo1.c )]);
  my $object = $file->build_item;
  isa_ok $object, 'FFI::Build::File::Object';

  is
    [ $object->build_item ],
    [];

  cleanup 'corpus/ffi_build_file_c/_build';

};

subtest 'headers' => sub {

  my $build = FFI::Build->new('foo',
    verbose => 2,
    cflags  => "-Icorpus/ffi_build_file_c/include",
  );

  note "cflags=$_" for @{ $build->cflags };

  my $file = FFI::Build::File::C->new([qw( corpus ffi_build_file_c foo2.c )], build => $build );

  my @deps = eval { $file->_deps };
  is $@, '', 'no die';

  foreach my $dep (@deps)
  {
    ok -f "$dep", "dep is a file: $dep";
  }

};

done_testing;
