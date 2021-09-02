use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build::File::CXX;
use FFI::Build;
use FFI::Build::Platform;
use Capture::Tiny qw( capture_merged );

skip_all 'Test requires C++ compiler'
  unless eval { FFI::Build::Platform->which(FFI::Build::Platform->cxx) };

subtest 'basic' => sub {

  my $file = FFI::Build::File::CXX->new(['corpus','ffi_build_file_cxx','basic.cxx']);

  isa_ok $file, 'FFI::Build::File::CXX';
  isa_ok $file, 'FFI::Build::File::C';
  isa_ok $file, 'FFI::Build::File::Base';
  is($file->default_suffix, '.cxx');
  is($file->default_encoding, ':utf8');

};

subtest 'compile' => sub {

  my $file = FFI::Build::File::CXX->new([qw( corpus ffi_build_file_cxx foo1.cxx )]);
  my $object = $file->build_item;
  isa_ok $object, 'FFI::Build::File::Object';

  is
    [ $object->build_item ],
    [];

  cleanup 'corpus/ffi_build_file_cxx/_build';

};

subtest 'headers' => sub {

  my $build = FFI::Build->new('foo',
    verbose => 2,
    cflags  => "-Icorpus/ffi_build_file_cxx/include",
  );

  note "cflags=$_" for @{ $build->cflags };

  my $file = FFI::Build::File::C->new([qw( corpus ffi_build_file_cxx foo2.cpp )], build => $build );

  my @deps = eval { $file->_deps };
  is $@, '', 'no die';

  foreach my $dep (@deps)
  {
    ok -f "$dep", "dep is afile: $dep";
  }

};

done_testing;
