use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test::Cleanup;
use Test::Platypus;
use FFI::Build;
use FFI::Build::Platform;
use FFI::Temp;
use Capture::Tiny qw( capture_merged );
use File::Spec;
use File::Path qw( rmtree );
use File::Glob qw( bsd_glob );

subtest 'basic' => sub {

  my $build = FFI::Build->new('foo');
  isa_ok $build, 'FFI::Build';
  like $build->file->path, qr/foo/, 'foo is somewhere in the native name for the lib';
  note "lib.file.path = @{[ $build->file->path ]}";

  ok(-d $build->file->dirname, "dir is a dir" );
  isa_ok $build->platform, 'FFI::Build::Platform';

  $build->source('corpus/ffi_build/source/*.c');

  my($cfile) = $build->source;
  isa_ok $cfile, 'FFI::Build::File::C';

};

subtest 'file classes' => sub {
  {
    package FFI::Build::File::Foo1;
    use parent qw( FFI::Build::File::Base );
    $INC{'FFI/Build/File/Foo1.pm'} = __FILE__;
  }

  {
    package FFI::Build::File::Foo2;
    use parent qw( FFI::Build::File::Base );
  }

  my @list = FFI::Build::_file_classes();
  ok( @list > 0, "at least one" );
  note "class = $_" for @list;
};

subtest 'build' => sub {

  foreach my $type (qw( name object array ))
  {

    subtest $type => sub {

      my $tempdir = FFI::Temp->newdir;

      my $build = FFI::Build->new('foo',
        dir       => $tempdir,
        buildname => "tmpbuild.tmpbuild.$$.@{[ time ]}",
        verbose   => 2,
      );

      my @source;

      if($type eq 'name')
      {
        @source = 'corpus/ffi_build/project1/*.c';
      }
      elsif($type eq 'object')
      {
        @source = map { FFI::Build::File::C->new($_) } bsd_glob('corpus/ffi_build/project1/*.c');
      }
      elsif($type eq 'array')
      {
        @source = map { [ C => $_ ] } bsd_glob('corpus/ffi_build/project1/*.c');
      }

      $build->source(@source);
      note "$_" for $build->source;

      my($out, $dll, $error) = capture_merged {
        my $dll = eval { $build->build };
        ($dll, $@);
      };

      ok $error eq '', 'no error';

      if($error)
      {
        diag $out;
        return;
      }
      else
      {
        note $out;
      }

      platypus 2 => sub {
        my $ffi = shift;
        $ffi->lib($dll);

        is(
          $ffi->function(foo1 => [] => 'int')->call,
          42,
        );

        is(
          $ffi->function(foo2 => [] => 'string')->call,
          "42",
        );
      };

      $build->clean;

      cleanup(
        $build->file->dirname,
        File::Spec->catdir(qw( corpus ffi_build project1 ), $build->buildname)
      );
    };
  }

};

subtest 'build c++' => sub {

  skip_all 'Test requires C++ compiler'
    unless eval { FFI::Build::Platform->which(FFI::Build::Platform->cxx) };

  my $tempdir = FFI::Temp->newdir( TEMPLATE => "tmpbuild.XXXXXX" );

  my $build = FFI::Build->new('foo',
    dir       => $tempdir,
    buildname => "tmpbuild.$$.@{[ time ]}",,
    verbose   => 2,
  );

  $build->source('corpus/ffi_build/project-cxx/*.cxx');
  $build->source('corpus/ffi_build/project-cxx/*.cpp');
  note "$_" for $build->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $build->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }

  platypus 2 => sub {
    my $ffi = shift;
    $ffi->lib($dll);

    my $foo1 = eval { $ffi->function( foo1 => [] => 'int'    ) };
    my $foo2 = eval { $ffi->function( foo2 => [] => 'string' ) };

    ok defined $foo1, "foo1 found";
    ok defined $foo2, "foo2 found";


    SKIP: {
      if(defined $foo1 && defined $foo2)
      {
        is(
          $ffi->function(foo1 => [] => 'int')->call,
          42,
        );
        is(
          $ffi->function(foo2 => [] => 'string')->call,
          "42",
        );
      }
      else
      {
        diag "[build log follows]\n";
        diag $out;
        skip "foo1 or foo2 not found", 2 unless defined $foo1 && defined $foo2;
      }
    }
  };

  $build->clean;

  cleanup(
    $build->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project-cxx ), $build->buildname)
  );

};

subtest 'alien' => sub {

  skip_all 'Test requires Acme::Alien::DontPanic 1.03'
    unless eval { require Acme::Alien::DontPanic; Acme::Alien::DontPanic->VERSION("1.03") };


  my $tempdir = FFI::Temp->newdir( TEMPLATE => "tmpbuild.XXXXXX" );
  my $build = FFI::Build->new('bar',
    dir       => $tempdir,
    buildname => "tmpbuild.$$.@{[ time ]}",
    verbose   => 2,
    alien     => ['Acme::Alien::DontPanic'],
  );

  $build->source('corpus/ffi_build/project2/*.c');
  note "$_" for $build->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $build->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }

  platypus 1 => sub {
    my $ffi = shift;
    $ffi->lib($dll);

    is(
      $ffi->function(myanswer => [] => 'int')->call,
      42,
    );
  };

  cleanup(
    $build->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project2 ), $build->buildname)
  );
};

done_testing;
